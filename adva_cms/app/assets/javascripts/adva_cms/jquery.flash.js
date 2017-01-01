(function($) {
  var Flash = function(root) {
    return $.extend({}, Flash, { $root: $(root) });
  };

  Flash = $.extend(Flash, {
    transferFromCookies: function() {
      var data = JSON.parse(unescape(Cookie.get('flash')).replace(/\+/g, ' '));
      if(!data) data = {};
      this.data = data;
      Cookie.erase('flash');
    },
    show: function(type, message) {
      if(!this.data || this.data == {}) this.transferFromCookies();

      var flash = this.$root.find('#flash_' + type);
      // if no message is given, look it up in the hash
      if(!message) message = this.data[type];

      if(!message && type == 'error') message = this.data['alert'];

      if(!message) return;
      
      if(message.toString().match(/<li/)) message = "<ul>" + message + '</ul>'
      flash.html(message);

      flash.show();
    },
    
    showAll: function() {
      this.show('error');
      this.show('notice');
    },
    
    error: function(message) {
      this.show('error', message);
    },

    notice: function(message) {
      this.show('notice', message);
    },

    hide: function(type) {
      this.$root.find('#flash_' + type).empty().hide();
    },

    hideAll: function() {
      this.hide('error');
      this.hide('notice');
    }
  });

  $(document).ready(function() {
    Flash.$root = $("body");
    Flash.showAll();
  });

  window.Flash = Flash;
})(jQuery);
