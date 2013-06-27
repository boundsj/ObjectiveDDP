Things = new Meteor.Collection('things');
Lists = new Meteor.Collection('lists');

if (Meteor.isClient) {
  Meteor.subscribe('things');
  Meteor.subscribe('lists');

  Template.main.things = function () {
    return Things.find({listName: Session.get('list-name')});
  };

  Template.main.lists = function() {
    return Lists.find();
  };

  Template.main.events({
    'click .add-item': function () {
        $('.todo-input').removeClass('hidden');
    },

    'blur .todo-input': function() {
        var todoInput = $('.todo-input');
        todoInput.addClass('hidden');
        Things.insert({
            msg: todoInput.val(),
            owner: Meteor.userId(),
            listName: Session.get('list-name'),
            share_with: Session.get('share-with'),
            listOwner: Session.get('list-owner')
        });
    },

    'click .remove-item': function() {
        Things.remove(this._id);
    },

    'click .add-list': function () {
        $('.list-input').removeClass('hidden');
    },

    'blur .list-input': function() {
        var listInput = $('.list-input');
        listInput.addClass('hidden');
        Lists.insert({
            name: listInput.val(),
            owner: Meteor.userId()
        });
        Session.set('list-name', listInput.val());
    },

    'click .list-name': function() {
        Session.set('list-name', this.name);
        Session.set('share-with', this.share_with);
        Session.set('list-owner', this.owner);
    },

    'click .remove-list': function() {
        Lists.remove(this._id);
    },

    'click .share-list': function() {
        var self = this;
        $("." + this._id).popover('destroy');
        var content = '<input class="share-input" value="name@email.com"></input><a href="#" class="btn cancel-share">Cancel</a><a href="#" class="btn send-share">Send</a>';
        $("." + this._id).popover({ title: 'Invite a Friend! ' + this._id, content: content, html: true });
        $("." + this._id).popover('show');
        $(".cancel-share").click(function() {
          $("." + self._id).popover('destroy');
        });
        $(".send-share").click(function() {
          $("." + self._id).popover('destroy');
          var email = $('.share-input').val();
          Lists.update(self._id, {$set: {share_with: email}});
          Meteor.call('updateRelatedThings', self.name, email);
        });
    }
  });
}

if (Meteor.isServer) {
  Meteor.startup(function () {
    var getEmailFromUserId = function(userId) {
      var email = Meteor.users.findOne({_id: userId }, {emails: 1});
      if (email && email['emails']) {
        return email['emails'][0]['address'];
      }
      return null;
    }
    var getUserIdFromEmail = function(email) {
      return Meteor.users.findOne({"emails.address": {$in: [email]}}, {_id: 1})
    }

    Meteor.publish('things', function() {
      return Things.find({$or: [{"share_with": getEmailFromUserId(this.userId)},
                                {"owner": this.userId},
                                {"listOwner": this.userId}]});
    });

    Meteor.publish('lists', function() {
      return Lists.find({$or: [{"share_with": getEmailFromUserId(this.userId)},
                               {"owner": this.userId}]});
    });

    Things.allow({
      insert: function(userId, doc) {
        return (userId && doc.owner === userId);
      },

      remove: function(userId, doc) {
        return (userId && (doc.owner === userId || doc.share_with === getEmailFromUserId(userId) || doc.listOwner === userId));
      }
    });

    Lists.allow({
      insert: function(userId, doc) {
        return (userId && doc.owner === userId);
      },

      remove: function(userId, doc) {
        var allow = (userId && doc.owner === userId);
        deleteRelatedThings(allow, doc);
        return allow;
      },

      update: function(userId, doc) {
        return (userId && doc.owner === userId);
      }
    });
  });

  Meteor.methods({
    updateRelatedThings: function(listName, shareWith) {
      Things.update({listName: listName}, {$set: {share_with: shareWith}}, {multi: true});
    }
  });

  var deleteRelatedThings = function(allow, doc) {
      // this breaks because allow is done for the list, not for the listName
      // we could lose all Things that have a name "blarg" even if "blarg"
      // is on two totally diff lists
    if (allow) {
      Things.remove({listName: doc.name});
    }
  }
}
