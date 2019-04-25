module DisplayHelper
  def render_text_sum(resource)
    html = ActiveSupport::SafeBuffer.new
    html << content_tag(:div, class: 'sum_as_text') do
      currency_to_words(resource.is_a?(Numeric) ? resource : resource.sum_with_vat)
    end
    html
  end

  def currency_to_words(number)
    num_parts = split_number(number)
    to_words(num_parts)
  end

  def split_number(number)
    options_precision = {
      :precision => 2,
      :delimiter => '',
      :significant => false,
      :strip_insignificant_zeros => false,
      :separator => '.',
      :raise => true
    }
    rounded = number_with_precision(number, options_precision)
    rounded.split(options_precision[:separator]).map(&:to_i)
  end

  def to_words(number)
    "#{with_currency(number[0], 'unit')}#{with_currency(number[1], 'decimal')}"
  end

  def with_currency(number, type)
    last_number = last_num(number)
    amount = last_number == 1 ? 'one' : 'many'
    currency = SystemSetting.value_for('default_currency')
    translation = "#{currency}.#{type}.#{amount}"
    "#{number.to_words} #{t("currency.#{translation}")} "
  end

  def color_label(color)
    content_tag(:span, color, class: 'label',
      style: "background-color: #{color}")
  end

  def last_num(number)
    numbers = number.to_s.split('')
    if numbers.count > 1
      return 2 if numbers[-1] == 1 && numbers[-2] == 1
    end
    numbers[-1].to_f
  end

  def render_assigned_users(users, main_user)
    html = ActiveSupport::SafeBuffer.new
    users.uniq.each do |user|
      if user && user.id != main_user.try(:id)
        html << render_person_box(user, 'person_box')
      end
    end
    html
  end

  def render_person_box(person, klass, name = nil, options = {})
    if person
      person_name = name || person.name
      content_tag(:a, nil, class: klass, href: url_for(person)) do
        image_tag(person.avatar.url(options[:image_style] || :small_thumb),
          class: 'project_person_avatar') +
          content_tag(:p, person_name, class: 'person_name')
      end
    end
  end

  def modal_date_row(event)
    content_tag(:i, nil, class: "fa fa-clock-o right_sp") +
      content_tag(:span, date_string(event.start_at).to_s, class: "right_sp") +
      content_tag(:i, nil, class: 'fa fa-chevron-right until_icon') +
      content_tag(:span, date_string(event.end_at).to_s, class: "left_sp")
  end

  def separated_date(object, event)
    content_tag(:div, nil, class: 'show_date_item_1') do
      content_tag(:span,
         "#{t('activerecord.attributes.calendar_event.from')}: ",
           class: 'date_item_span') +
        editable_datetime_field(object, event, event.start_at, 'start_at')
    end +
      content_tag(:div, nil, class: 'show_date_item_2') do
        content_tag(:span,
          "#{t('activerecord.attributes.calendar_event.till')}: ",
           class: 'date_item_span') +
          editable_datetime_field(object, event, event.end_at, 'end_at')
      end
  end

  def date_string(date)
    date.to_datetime.strftime('%d-%m-%Y %H:%M')
  end

  def render_creater_owner_column(owner, creator)
    if owner && creator
      content_tag(:div, nil, class: 'creator_owner_box') do
        if owner == creator
          render_creator_owner_item('Izpildītājs', owner)
        else
          render_creator_owner_item('Izpildītājs', owner) +
            render_creator_owner_item('Izveidotājs', creator)
        end
      end
    end
  end

  def render_creator_owner_item(title, person, options = {})
    content_tag(:p, title, class: 'creator_owner_label') +
      render_person_box(person, 'modal_persons_box', person.to_s, options)
  end

  def render_customer_column(customer)
    if customer
      content_tag(:div, nil, class: 'creator_owner_box') do
        render_creator_owner_item(t('activerecord.models.customer'), customer,
          image_style: :thumb)
      end
    end
  end

  def from_to_date(date_from, date_to)
    if date_from && date_to
      content_tag(:span, date_string(date_from).to_s, class: "right_sp") +
        content_tag(:i, nil, class: 'fa fa-chevron-right until_icon') +
        content_tag(:span, date_string(date_to).to_s, class: "left_sp")
    else
      "-"
    end
  end

  def render_contact_map(addresses)
    content_tag(:div, nil, class: 'customer_contact_map', id: 'contact_map',
      data: { addresses: addresses })
  end

  def render_boolean_source
    return_array = []
    return_array << { value: 1, text: t('show_for.yes') }
    return_array << { value: 0, text: t('show_for.no') }
    return_array
  end

  def render_source_array(elements, options = {})
    value_method = options[:value_method] || 'id'
    text_method = options[:text_method] || 'value'
    return_array = []
    elements.each do |element|
      return_array << { value: element.try(value_method), text: element.try(text_method) }
    end
    return_array
  end

  def available_states(object, class_name)
    @available_states ||= get_all_states(object, class_name)
  end

  def states_select(object, class_name, states)
    return_array = []
    states.each do |state|
      return_array << { value: state.id,
       text: state.to_s, color: state.color }
    end
    return_array
  end

  def round_item(item)
    format("%0.02f", item)
  end

  def display_decimal(number, options = {})
    return '0.00' unless number
    if options[:round_method]
      number = number.send(options[:round_method], options[:round_to] || 2)
    end
    options_precision = {
      :precision => 2,
      :delimiter => '',
      :significant => false,
      :strip_insignificant_zeros => false,
      :separator => '.',
      :raise => true
    }
    number_with_precision(number, options_precision)
  end

  def collapsible_box(title, options = {}, &block)
    classes = ['box', 'box-primary']
    classes << 'collapsed-box' if options[:collapse]
    classes << 'form-collapsed-box' if options[:form]
    html = ActiveSupport::SafeBuffer.new
    html << collapsible_box_head(title, options) unless options[:label] == false
    html << \
      content_tag(:div, class: 'box-body') do
        capture(&block)
      end
    content_tag(:div, class: "col-md-#{options[:size] || 12}") do
      content_tag(:div, class: classes) do
        html
      end
    end
  end

  def collapsible_box_head(title, options)
    title = options[:title] || t("data_blocks.#{title}")
    postfix = options[:title_postfix] || ""
    content_tag(:div, class: 'box-header with-border') do
      content_tag(:h3, title + postfix, class: 'box-title') +
        content_tag(:div, class: "box-tools pull-right") do
          if options[:no_collapsable]
            ActiveSupport::SafeBuffer.new
          else
            content_tag(:button, class: "btn btn-box-tool",
              data: { widget: "collapse" }) do
              content_tag(:i, nil,
                class: "fa fa-#{options[:collapse] ? 'plus' : 'minus'}")
            end
          end
        end
    end
  end

  def drag_indicator(options = {})
    klass = options[:class] || 'drag-indicator'
    content_tag(:div, class: klass) do
      content_tag(:i, nil, class: 'fa fa-bars') +
        content_tag(:i, nil, class: 'fa fa-bars')
    end
  end

  def vertical_drag_indicator(options = {})
    klass = ['list-item-drag-indicator']
    klass << options[:class]
    klass.reject!(&:blank?)
    drag_indicator(class: klass)
  end

  def show_for_title_with_count(title, count, icon = nil)
    count = nil unless count.to_i >= 0
    html = ActiveSupport::SafeBuffer.new
    html << content_tag(:i, nil, class: icon, style: 'margin-right: 5px;') if icon
    html << content_tag(:h3, title, class: 'box-title')
    if count >= 0
      hide = count.zero? ? 'hidden' : ''
      html << content_tag(:span, count, class: "tab_item_count_lg label label-default #{hide}")
    end
    content_tag(:div, html)
  end

  def display_board_lists_item_count(resource)
    return unless resource
    html = ActiveSupport::SafeBuffer.new
    states = %i(to_do in_progress done)
    size = resource.is_a?(Board) ? 3 : 4
    states.each do |state|
      html << content_tag(:div, resource.board_item_count(state.to_s),
        class: "col-md-#{size} #{state}_count",
        title: BoardList.human_keys[state])
    end
    if resource.is_a?(Board)
      html << content_tag(:div, resource.board_items.archived.count,
        class: 'col-md-3 archived_count',
        title: t('boards.archived_items'))
    end
    content_tag(:div, html, class: 'board_lists_item_count')
  end

  def file_content_type_tag(file_attachment)
    title = \
      if file_attachment.image?
        file = file_attachment.file
        url = file.url(:small_thumb)
        url = file.url(:thumb) unless file.exists?(:small_thumb)
        image_tag(url)
      else
        content_tag(:div, file_attachment.file_file_name.split('.').last,
          class: 'file_attachment_content_type')
      end
    link_to title, file_attachment.file.url, target: '_blank'
  end

  def related_resource_box(resource, related_resource, options = {})
    rel = related_resource.relatable
    rel = related_resource.resource if related_resource.relatable == resource
    return unless rel
    div_content = \
      content_tag(:i, nil, class: "fa fa-#{rel.class.try(:icon)} icon-box") +
      related_resource_link(rel, options) +
      delete_link(related_resource,
        remote: options[:del_remote],
        url: [resource, related_resource],
        class: 'delete-icon')
    content_tag(:div, div_content,
      id: "email_related_resource_#{related_resource.id}",
      class: 'related-resource-link-with-icon',
      title: rel.to_s)
  end
end
