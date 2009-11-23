# coding:utf-8
module PublicHelper
  def public_menu name,options={}
    current_branch = get_current_menu_branch(name)
    public_menu_items(name) do |item|
      yield menu_item_link_to(item,current_branch,options),current_branch.include?(item)? item : nil
    end
  end

  def public_menu_items name
    main_menu = Admin::Menu.find_by_menu_name(name);
    if main_menu
      items = main_menu.level1_published_items
      items.each{|item|
         yield item
      }
    else
      raise "Izvēlne #{name} nav atrasta!"
    end
  end

  def public_items_from item,options={}
    current_branch=get_current_menu_branch(item.menu.menu_name)
    item.children.each{|child_item|
      yield menu_item_link_to(child_item,current_branch,options),current_branch.include?(child_item),child_item
    }
  end
end
