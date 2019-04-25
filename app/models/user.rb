class User < ApplicationRecord

  attr_accessor :password_confirmation

  # self.icon = 'users'

  after_touch :touch_with_version

  class_attribute :autocomplete_params
  self.autocomplete_params = 'name_or_surname'

  # devise :invitable, :database_authenticatable, :omniauthable,
  #        :recoverable, :rememberable, :trackable, :validatable, :lockable,
  #        :doorkeeper

  validates :email, :name, :surname, presence: true
  validate :validates_password_confirmation
  validates :password, length: { in: 8..128 },
    on: [:update, :create],
    allow_blank: true

  has_many :albums
  has_many :table_settings, dependent: :destroy
  has_many :customers
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :file_attachments, as: :attachable, dependent: :destroy
  has_many :image_attachments, as: :attachable, dependent: :destroy
  has_many :owned_calendar_events, class_name: 'CalendarEvent',
    foreign_key: :owner_id
  has_many :owned_activities, through: :owned_calendar_events,
    source: :calendarable, source_type: 'Activity'
  has_many :activity_resources, as: :activitable, dependent: :destroy
  has_many :related_activities, through: :activity_resources, source: :activity
  belongs_to :inviter, class_name: 'User', foreign_key: :invited_by_id
  belongs_to :occupation
  belongs_to :user_group
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :notification_settings
  has_many :system_messages, foreign_key: :recipient_id
  has_many :messages, foreign_key: :recipient_id
  has_many :classifier_permissions
  has_many :activity_logs, class_name: "ActivityLog"
  has_many :owned_board_items, class_name: 'BoardItem',
    foreign_key: :owner_id
  has_many :created_board_items, class_name: 'BoardItem',
    foreign_key: :creator_id
  has_many :owned_boards, through: :owned_board_items, source: :board
  has_many :google_calendar_users
  has_many :google_calendars, through: :google_calendar_users
  has_many :email_accounts, -> { order('position asc') }, dependent: :destroy
  has_many :email_account_folders, through: :email_accounts
  has_many :accounts_email_messages, through: :email_accounts,
    class_name: 'EmailMessage', source: :email_messages
  has_many :sent_email_messages, class_name: 'EmailMessage', source: :email_messages
  has_many :email_address_books
  has_many :sync_access_tokens
  has_many :downloads
  has_many :permissions, (-> { uniq }), through: :roles

  has_many :access_grants, class_name: "Doorkeeper::AccessGrant",
                           foreign_key: :resource_owner_id,
                           dependent: :delete_all # or :destroy if you need callbacks

  has_many :access_tokens, class_name: "Doorkeeper::AccessToken",
                           foreign_key: :resource_owner_id,
                           dependent: :delete_all # or :destroy if you need callbacks

  ClassifierPermission.configurable_classifiers.each do |classifier|
    has_many :"available_#{classifier.name.tableize}", (
      lambda do
        where 'user_classifiers.type = ?', classifier.name
      end),
      through: :classifier_permissions,
      source: 'user_classifier'
  end

  accepts_nested_attributes_for :notification_settings

  update_indexes :self

  scope :superadmins, (-> { unscoped.where(key: 'superadmin') })

  scope :blocked, (-> { where(is_blocked: true) })

  scope :not_blocked, (-> { where(is_blocked: false) })

  scope :unconfirmed, (lambda do
    where('invitation_accepted_at IS NULL OR invitation_sent_at IS NULL')
  end)

  scope :birthdays, (lambda do |date|
    where('month(birthday) = ? and day(birthday) = ?',
          date.month, date.day)
  end)

  scope :namedays, (lambda do |date|
    where(name: CelebrationDays.name_days.split(', '))
  end)

  scope :my_unread_email_messages, (lambda do
    current.accounts_email_messages.try(:not_seen)
      .joins(:email_account_folder)
      .where.not("email_account_folders.folder_type
        IN ('sent', 'trash', 'drafts', 'junk', 'spam')
        OR email_account_folders.name IN ('sent', 'trash', 'drafts', 'junk', 'spam')")
      .count
  end)

  accepts_nested_attributes_for :contacts, allow_destroy: true,
    reject_if: :all_blank

  classifier :gender, {
    key: 'cod.gender',
    values: %w(male female unknown)
  }

  has_attached_file :avatar, styles: { thumb: "100x100", medium: "160x160#",
   small_thumb: "65x65#" }, default_url: 'missing/user_:style.png'
  validates_attachment_content_type :avatar, :content_type => /image/

  before_save :set_defaults

  def self.method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^group_(.*)$/
      id = method_sym.to_s.split('_').last
      joins(:user_group).where(user_classifiers: { id: id })
    else
      super
    end
  end

  def avatar_url
    if avatar_file_name?
      "#{ENV['DEFAULT_MAILER_HOST']}#{avatar.url(:medium, timestamp: false)}"
    else
      ''
    end
  end

  def google_oauth2_auth(auth)
    c_user = google_calendar_users.find_or_create_by(email: auth.info.email)
    credentials = auth.credentials
    c_user.access_token = credentials.token
    c_user.refresh_token = credentials.refresh_token
    c_user.save
  end

  def set_defaults
    self.initials = "#{name[0]}#{surname[0]}" if initials.blank?
    self.gender = 'unknown' if gender.blank?
    set_default_avatar
  end

  def set_default_avatar
    if avatar.blank?
      uri = URI.parse('https://ui-avatars.com/api/?name=' + name.parameterize + \
      '+' + surname.parameterize + '&size=160')
      self.avatar = uri.open
    end
  end

  def primary_phone
    main_phone || main_mob_phone || OwnerSetting.current.primary_phone
  end

  def invited_but_not_accepted?
    invitation_created_at && invitation_accepted_at.nil?
  end

  def block!
    update_attribute(:is_blocked, true)
  end

  def unblock!
    update_attribute(:is_blocked, false)
  end

  def blocked?
    is_blocked
  end

  def active_for_authentication?
    super && !is_blocked?
  end

  def inactive_message
    is_blocked ? :user_is_blocked : super
  end

  def sign_in_happening?
    sign_in_count == sign_in_count_was + 1
  end

  def to_label
    "#{name} #{surname}"
  end

  def to_s
    "#{name} #{surname}"
  end

  def password_required?
    false
  end

  def occupation_name
    occupation.try(:value)
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end

  def to_json
    as_json(methods: [:occupation_name],
      :include => {
        legal_address: { methods: :to_s },
        main_bank_account: { methods: [:name_of_bank, :swiff_of_bank] },
        main_phone: { methods: :to_s },
        primary_phone: { methods: :to_s }
      })
  end

  def to_calendar
    {
      id: id,
      user_group: user_group,
      title: to_s
    }
  end

  def self.to_custom_json(query)
    if query.respond_to?(:map)
      JSON.generate(query.map(&:to_calendar))
    end
  end

  def superadmin?
    key == 'superadmin'
  end

  def google_calendars_as_collection
    google_calendars.synced.map do |gc|
      [gc.title, gc.calendar_id]
    end
  end

  def sync_calendars
    google_calendars.synced.find_each { |gc| gc.sync!(false) }
  end

  def board_item_count(key = nil)
    key = key.to_s
    if ['to_do', 'in_progress', 'done'].include?(key)
      owned_board_items.visible.where(key: key).count
    else
      owned_board_items.visible.count
    end
  end

  def sync_access_token
    sync_access_tokens.last
  end

  def perform_email_sync(offset = 60)
    return if email_accounts.blank?

    email_accounts.each do |ea|
      ea.add_sync_job(offset)
    end
  end

  private

  def validates_password_confirmation
    if password && password != password_confirmation
      errors.add(:password_confirmation, :should_math_with_password_field)
    end
  end
end
