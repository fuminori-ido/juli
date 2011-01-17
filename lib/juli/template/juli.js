Juli = {
  show: function(dom){
    $(dom).show();
    $(dom + "_p").hide();
    $(dom + "_m").show();
  },
  hide: function(dom){
    $(dom).hide();
    $(dom + "_p").show();
    $(dom + "_m").hide();
  },
  toggle: function(dom) {
    element = $(dom);
    if( Element.visible(element) )
      Juli.hide(dom);
    else
      Juli.show(dom);
  }
}
