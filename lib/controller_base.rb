require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require 'byebug'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, routes_params)
    @req = req
    @res = res
    @already_built_response = false
    @routes_params = routes_params
    @params = req.params.merge(routes_params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    if already_built_response?
      raise 'Render error'
    else
      # res['Location'] = url
      # ...OR:
      res.set_header("Location", url)
      res.status = 302
      @already_built_response = true
      session.store_session(res)
    end
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    if already_built_response?
      raise 'Render error'
    else
      # @res['Content-Type'] = content_type
      # ... OR:
      res.set_header('Content-Type', content_type)
      res.write(content)
      @already_built_response = true
      session.store_session(res)
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller_name = self.class.name.underscore
    path = "views/#{controller_name}/#{template_name}.html.erb"
    file_contents = File.read(path)
    html_view = ERB.new(file_contents).result(binding)
    render_content(html_view, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    Self.send(name)
    unless already_built_response?
      render(name)
    end
  end
end
