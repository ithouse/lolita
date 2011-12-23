#Lolita

Great Rails CMS, that turns your business logic into good-looking, fully functional workspace. 
Works with Rails 3.1
##Demo
See the demo page at [Demo](http://lolita-demo.ithouse.lv)

##Installation

First install Lolita gem
  
    sudo gem install lolita

Then go to your rails project and 
  
    rails g lolita:install

That will create initializer and copy all assets.
Also it will call *install* on all added modules to lolita. 
So if you in Gemfile have following

```ruby  
  gem "lolita"
  gem "lolita-file-upload"
```

It will also call *lolita_file_upload:install*.
##Usage
 
To make your model use Lolita do like this

```ruby
  class Post < ActiveRecord::Base
    include Lolita::Configuration
    lolita
  end
```

Then in routes.rb file make resources accessable for lolita with  
  
    lolita_for :posts
This will make routes like
  `/lolita/posts`
  `/lolita/posts/1/edit`
  `/lolita/posts/new`
or open `/lolita` and it will redirect to first available resource list view.

For more detailed usage read [Usage](https://github.com/ithouse/lolita/wiki/Usage) at wiki.

###Add authorization to Lolita

Easiest way to add authentication is with Devise. First install Devise as gem, than add it to your project.
Make Devise model, lets say, *User*. After that add these lines in */config/initializers/lolita.rb*

```ruby
  config.user_classes << User
  config.authentication = :authenticate_user!
```

This will make before each Lolita requests call before filter, that than will call *authenticate_user!*
that is Devise method for authenticating user. Without it Lolita will be acessable for everyone.
You can also add any other authentication method like

```ruby
  config.authentication = :authenticate_admin
```

And than put this method for common use in *ApplicationController* or in some other place that is accessable
to all controllers.

###Using hooks

Lolita define hooks for RestController and for components.
####RestController hooks

There are two kind of hooks for all actions - *before_[action name]* and *after_[action name]*.
Define callbacks for those hooks outside of controller. This will call User#log_action each time when #destroy 
action is requested.

```ruby
  Lolita::RestController.before_destroy do
    User.log_action("Going to delete #{params[:id]}") 
  end
```

Also you can define callbacks in your controllers that extend Lolita::RestController. This will call #set\_default\_params
each time #new action is requested.

```ruby
  class PostController < Lolita::RestController
    before_new :set_default_params

    private

    def set_default_params
      params[:post][:title]="-Your title goes here-"
    end
  end
```

####Component hooks

Components have three hooks - *before*, *after* and *around*.
Component hooks are different from controller hooks with names. Each component has it's own name, that is used to
call component, like

```ruby
  render_component :"lolita/configuration/list/display"
  #same as
  render_component :"lolita/configuration/list", :display
```

and this name is used to add callback for component. As components is not related to specific class, then there
are only one way to define callback for them.

```ruby
  Lolita::Hooks.component(:"/lolita/configuration/list/display").before do
    "<div>My Custom text</div>"
  end
```

That what are inside of blocks depends on place where you define callback if it is in _.rb_ file, than you
should put HTML in quotes, if in _.erb_ and similar files then there is no need for that. Also blocks with 
Ruby code only return last line, so you should probably define HTML as shown in previous example.
For _around_ callback if you pass block, then original content will be replaced with that, but if you want
to let original content inside of your block content than it is done like this with #let_content method.

```ruby
  Lolita::Hooks.component(:"/lolita/configuration/list/display").around do
    "<div style='color:red'>#{let_content}</div>"
  end
```

##License

Lolita is under MIT license. See [LICENSE.txt](https://github.com/ithouse/lolita/blob/master/LICENSE.txt)