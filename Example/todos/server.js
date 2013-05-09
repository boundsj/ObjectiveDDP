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
            listName: Session.get('list-name')
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
        var listName = this.name;
        Session.set('list-name', listName);
    },
    'click .remove-list': function() {
        Lists.remove(this._id);
    }
  });
}

if (Meteor.isServer) {
  Meteor.startup(function () {
    Meteor.publish('things', function() {
      return Things.find({owner: this.userId});
    });

    Meteor.publish('lists', function() {
      return Lists.find({owner: this.userId});
    });

    Things.allow({
      insert: function(userId, doc) {
        return (userId && doc.owner === userId);
      },

      remove: function(userId, doc) {
        return (userId && doc.owner === userId);
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
      }
    });
  });

  var deleteRelatedThings = function(allow, doc) {
    if (allow) {
      Things.remove({listName: doc.name});
    }
  }
}
