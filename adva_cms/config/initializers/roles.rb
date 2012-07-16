# Role hierarchy, predefined by rbac gem:
# superuser -> admin -> designer -> moderator -> author -> user
#
# Everything a author can do, can be done by his masters (superuser, admin, designer, moderator).
# E.g., if the permission :'show site' => [:author] is defined in the default_permissions,
# a superuser, admin, designer and moderator have permission for the action 'show site', too.

ActionDispatch::Callbacks.to_prepare do
  Rbac::Context.default_permissions = {
    :'show site'          => [:author],
    :'create site'        => [:superuser],
    :'update site'        => [:superuser],
    :'destroy site'       => [:superuser],
    :'manage site'        => [:superuser],

    :'show section'       => [:author],
    :'create section'     => [:moderator],
    :'update section'     => [:moderator],
    :'destroy section'    => [:moderator],
    :'manage section'     => [:moderator],

    # article permissions (except 'update article') are only checked by the Admin::ArticlesController
    :'show article'       => [:author],
    :'create article'     => [:author],
    :'update article'     => [:author], # important for live site, if article is a draft, it will be shown only if user has this permission
    :'destroy article'    => [:author],
    :'manage article'     => [:author],

    :'show link'          => [:moderator],
    :'create link'        => [:moderator],
    :'update link'        => [:moderator],
    :'destroy link'       => [:moderator],
    :'manage link'        => [:moderator],

    :'show content'       => [:moderator],
    :'create content'     => [:moderator],
    :'update content'     => [:moderator],
    :'destroy content'    => [:moderator],
    :'manage content'     => [:moderator],

    :'show comment'       => [:anonymous], # not guarded on live site
    :'create comment'     => [:anonymous], # used on the live site
    :'update comment'     => [:moderator],
    :'destroy comment'    => [:moderator],
    :'manage comment'     => [:moderator],

    :'show user'          => [:admin],
    :'create user'        => [:admin],
    :'update user'        => [:admin],
    :'destroy user'       => [:admin],
    :'manage user'        => [:admin],

    :'manage cached_page' => [:admin],

    :'manage roles'       => [:admin],

    :'show category'      => [:author],
    :'create category'    => [:author],
    :'update category'    => [:author],
    :'destroy category'   => [:author],
    :'manage category'    => [:author]
  }

  # Rbac.define do
    # role :anonymous,
    #      :grant => true
    #
    # role :user,
    #      :grant => :registered?,
    #      :parent => :anonymous,
    #      :message => :'adva.roles.errors.messages.not_logged_in'
    #
    # role :author,
    #      :require_context => Content,
    #      :grant => lambda{|context, user| context && !!context.try(:is_author?, user) },
    #      :parent => :user,
    #      :message => :'adva.roles.errors.messages.not_an_author'
    #
    # role :moderator,
    #      :require_context => Section,
    #      :parent => :author,
    #      :message => :'adva.roles.errors.messages.not_a_moderator'
    #
    # role :admin,
    #      :require_context => Site,
    #      :parent => :moderator,
    #      :message => :'adva.roles.errors.messages.not_an_admin'
    #
    # role :superuser,
    #      :parent => :admin,
    #      :message => :'adva.roles.errors.messages.not_a_superuser'
  # end
end
