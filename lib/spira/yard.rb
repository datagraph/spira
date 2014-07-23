# A small YARD handler for processing Spira properties.
#
# This handler processes {property} and {has_many} calls inside classes and
# transforms them into attribute definitions. Document them as you would
# `attr_accessor`.
#
# @example Using it from a Rakefile
#   require 'yard'
#   require 'spira/yard'
#
#   YARD::Rake::YardocTask.new do |yard|
#     # Set YARD options.
#   end
class SpiraPropertyHandler < YARD::Handlers::Ruby::Base
  namespace_only
  handles method_call(:property), method_call(:has_many)

  def process
    name = statement.parameters.first.jump(:tstring_content, :ident).source
    namespace.attributes[scope][name] ||= SymbolHash[:read => nil, :write => nil]
    namespace.attributes[scope][name][:read] = MethodObject.new(namespace, name, scope) do |o|
      o.docstring = if statement.comments.to_s.empty?
                      "Returns the value of the `#{name}` property."
                    else
                      statement.comments
                    end
      if statement.method_name(true) == :has_many
        o.docstring.add_tag(YARD::Tags::Tag.new(:return, 'something', ['Set']))
      end
    end
    register namespace.attributes[scope][name][:read]

    if statement.method_name(true) != :has_many
      namespace.attributes[scope][name][:write] = MethodObject.new(namespace, "#{name}=", scope) do |o|
        o.docstring = if statement.comments.to_s.empty?
                        "Sets the value of the `#{name}` property."
                      else
                        statement.comments
                      end
        o.docstring.add_tag(YARD::Tags::Tag.new(:param, 'the value to set the `#{name}` property to', ['RDF::Value'], 'value')) unless o.docstring.tag(:param)
      end
      register namespace.attributes[scope][name][:write]
    end
  end
end
