var Juli = {
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

/*
slideshow handling class.

= How lib/juli/visitor/slidy.rb and lib/juli/template/slidy.html Collaborate

1. Juli::Visitor::Slidy VISITOR-pattern in juli(1) generates
   <div class='slide'>...</div> per level 1 headline contents.
1. Then, when viewing, JuliSlidy Javascript object gathers level 1 contents,
   and hide all contents except for the top slide.

So that not only wikipage but also <div class='slide'> elements in template
are also treated as a part of slide pages.
*/
var JuliSlidy = Class.create({
  initialize: function(){
    this.slides     = $$('.slide');
    this.curr_slide = 0;
    this.keydownCB  = this._keydownCB.bind(this);
    this.clickCB    = this.next.bind(this);
    this.show_top();
    this.show_footer();
  },

  // show top page only and hide all other pages
  show_top: function(){
    this.slides.each(function(slide){ slide.hide(); });
    this.slides[0].show();
  },

  // show footer
  show_footer: function(){
    $('total_page').update(this.slides.length);
    this.update_curr_page();
  },

  // update footer's curr_page
  update_curr_page: function(){
    $('curr_page').update(this.curr_slide + 1);
  },

  // navigate next page
  next: function(e){
    if( this.curr_slide < this.slides.length - 1 ){
      this.slides[this.curr_slide].hide();
      this.curr_slide++;
      this.slides[this.curr_slide].show();
      this.update_curr_page();
    }
  },

  // navigate previous page
  prev: function(e){
    if( this.curr_slide > 0 ){
      this.slides[this.curr_slide].hide();
      this.curr_slide--;
      this.slides[this.curr_slide].show();
      this.update_curr_page();
    }
  },
  _keydownCB: function(e){
    if( e.keyCode == Event.KEY_RIGHT ){
      this.next(e);
    }else if( e.keyCode == Event.KEY_LEFT ){
      this.prev(e);
    }
  }
});
