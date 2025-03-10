module BreadcrumbsHelper
  def render_breadcrumbs
    defined?(breadcrumbs) && breadcrumbs.respond_to?(:any?)
  end
end
