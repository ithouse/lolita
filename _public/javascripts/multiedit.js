/**
 * Copyright (c) 2009 Jānis Freibergs for IT House
 * see examples of input structures in multiedit partials
 */

/**
 * toggles the control container (that holds select/+ button) on/off depending on
 * a) any options left
 * b) max limit (set through .multiedit .max value) reached
 * c) max limit of sub-classes set through class="limit" title="{class}" value="{N}" elements
 */
function multi_control_toggle($multiedit)
{
  var limit_count=$multiedit.find('.max').val();
  if (limit_count=="undefined") limit_count=0
  var $control=$multiedit.find('.control');
  $multiedit.find('select').each(function(){
    var $submittable_items=$multiedit.find('li').not('.template, .deletable, .control')
    if ( !this.options.length || (limit_count && $submittable_items.length>=limit_count ) )
      $control.fadeOut('slow');
    else
      $control.fadeIn('slow');
  })
  $multiedit.find('.limit').each(function(){
    var $limitedOpts=$multiedit.find('option.'+$(this).attr('title'));
    if ($limitedOpts.length)
    {
      if ( $multiedit.find('li.'+$(this).attr('title')).length >= $(this).val() )
        $limitedOpts.attr('disabled','disabled');
      else
        $limitedOpts.removeAttr('disabled');
    }
  })
}
function multi_mirror_option($select,$li,$mirror)
{
  if ($mirror.val())
  {
    $select.append('<option class="'+$li.attr('class')+'" value="'+$mirror.val()+'">'+
      $mirror.attr('title')+'</option>')
    $select[0].selectedIndex=$select[0].options.length-1
  }
}
/**
 * responds to a class="toggle" element to move element back to options
 * and remove it from "existing items" DOM
 *
 * this - any .multiedit li sub-element
 **/
function multi_attr_toggle()
{
  var $li=$(this).closest('li');
  var $multiedit=$li.closest('.multiedit');
  var $mirror=$li.find('input.mirror');
  var $select=$multiedit.find('select');
  multi_mirror_option($select, $li, $mirror);
  $li.fadeOut('slow',function(){
    $(this).replaceWith('');
    multi_control_toggle($multiedit);
  });
  return false;//important to stop bubbling
}
/*
 * responds to a class="deletable" element to move element back to options
 * and/or hide item and set object[name...] to object[deletable_name...]
 *
 * this=any .multiedit li sub-element
 */
function multi_attr_mark_deletable()
{
  var $li=$(this).closest('li');
  var $multiedit=$li.closest('.multiedit');
  var $mirror=$li.find('input.mirror');
  var $select=$multiedit.find('select');
  multi_mirror_option($select, $li, $mirror);
  multi_control_toggle($multiedit);
  $li.find('input').each(function(){
    $(this).attr('name',$(this).attr('name').replace('multi_input','multi_input_deletable'))
  })
  $li.addClass('deletable').fadeOut('slow');
  return false;//important to stop bubbling
}
/*
 * handles appending items to "existing" list
 * element     = any current multiedit's sub-element
 * object_attr = HM/HABTM attribute name, e.g. product[category_ids]
 */
function multi_attr_stack(element,object_attr)
{
  var $multiedit=$(element).closest('.multiedit');
  var $sel=$multiedit.find('select');
  var $opt=$sel.find(':selected');
  if ($opt.attr('disabled')) return false;
  var template=$multiedit.find('.template').html();
  var rep={
    attr:object_attr,
    value:$opt.val(),
    text:$opt.text()
  }
  for (var placeholder in rep)
    template=template.replace( new RegExp('\{'+placeholder+'\}', 'mig' ), rep[placeholder] );
  var $li=$('<li style="display:none">'+template+'</'+'li>');
  $li.addClass($opt.attr('class'));
  $multiedit.find('.control').before($li.fadeIn('slow'));
  $li.find('input').slice(0,1).trigger('focus');
  if ($opt.val())
    $opt.remove();
  multi_control_toggle($multiedit);
  return true;
}
//set up of initial styles/handlers
$(function(){
  $('.multiedit').each(function(){
    $(this).find('ol').css( 'list-style-type',
      $(this).find('.max').length ? 'decimal-leading-zero': 'circle' )
    multi_control_toggle($(this));
  })
  $('.multiedit .toggle').live('click',multi_attr_toggle);
  $('.multiedit .deletable').live('click',multi_attr_mark_deletable);
})