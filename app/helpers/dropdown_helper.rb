module DropdownHelper

  # TODO: support split button dropdowns; use blocks to add list items
  class DropdownListItem
    include FormatHelper
    include ActionView::Helpers

    attr_accessor :options

    def initialize(options={})
      @options = options
    end

    def render
      content_tag :li, parse_type(options), options
    end

    def parse_type(options={})
      case options.delete(:type).try(:to_sym)
      when :link
        return link_to(options.delete(:text), options.delete(:link),
                       role: :menuitem, tabindex: -1)
      when :header
        prepend_class(options, 'dropdown-header')
        return options.delete(:text)
      when :divider
        prepend_class(options, 'divider')
        options[:role] = 'separator' and return nil
      else
      end
    end
  end

  class DropdownCreator
    include FormatHelper
    include ActionView::Helpers
    include ButtonHelper

    attr_accessor :content
    attr_accessor :list
    attr_accessor :options
    attr_accessor :btn_group_options
    attr_accessor :output_buffer

    def initialize(content, list, options)
      @content           = content
      @list              = list
      @options           = options
      @btn_group_options = options.delete(:btn_group_html) || {}
    end

    def render
      navbar, btn_id, align, direction, size, type = process_dropdown_options(options)

      btn_options  = button_options(content, size, type, btn_id, navbar)
      list_options = list_options(btn_id, align)

      tag = navbar ? :li : :div
      prepend_class(btn_group_options, 'btn-group',
                    (direction == :up ? 'dropup' : 'dropdown'))

      content_tag tag, btn_group_options do
        (dropdown_button(btn_options.deep_merge(options)) +
          dropdown_list(list, list_options)).html_safe
      end
    end

    private
    def process_dropdown_options(options)
      navbar    = options.delete(:category).try(:to_sym) == :navbar
      btn_id    = options.delete(:id) || "dropdown-#{SecureRandom.hex(3)}"
      active    = 'active' if options.delete(:active)
      align     = options.delete(:align).try(:to_sym)
      direction = options.delete(:direction).try(:to_sym)
      size      = get_btn_size(options.delete(:size))
      type      = get_btn_type(options.delete(:type))

      prepend_class(options, active)

      [navbar, btn_id, align, direction, size, "btn #{type}"]
    end

    def button_options(content, size, type, id, navbar)
      klass = navbar ? 'dropdown-toggle' : "dropdown-toggle #{size} #{type}"
      prepend_class(options, klass)

      {
        content: content,
        id: id,
        type: 'button',
        data: {toggle: 'dropdown'},
        aria: {haspopup: true, expended: false},
        navbar: navbar
      }
    end

    def list_options(btn_id, align)
      {
        class: align == :right ? 'dropdown-menu-right' : 'dropdown-menu-left',
        role: 'menu',
        aria: {labelledby: btn_id}
      }
    end

    def dropdown_button(options={})
      content = options.delete(:content)
      navbar  = options.delete(:navbar)

      if navbar
        link_to '#', options do
          (content + " <span class='caret'></span>").html_safe
        end
      else
        button_tag options do
          (content + " <span class='caret'></span>").html_safe
        end
      end
    end

    def dropdown_list(list_items, options={})
      prepend_class(options, 'dropdown-menu')

      content_tag :ul, options do
        list_items.map do |item|
          DropdownListItem.new(item).render
        end.join('').html_safe
      end
    end
  end

  def dropdown(content=nil, list=[], options={})
    return if content.blank? || list.empty?

    DropdownCreator.new(content, list, options).render
  end
end
