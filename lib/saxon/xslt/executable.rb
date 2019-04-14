require 'forwardable'
require_relative 'evaluation_context'
require_relative '../serializer'
require_relative '../xdm_value'
require_relative '../qname'

module Saxon
  module XSLT
    # Represents a compiled XSLT stylesheet ready to be executed
    class Executable
      extend Forwardable

      attr_reader :evaluation_context
      private :evaluation_context

      # @api private
      # @param s9_xslt_executable [net.sf.saxon.s9api.XsltExecutable] the
      #   Saxon compiled XSLT object
      # @param evaluation_context [XSLT::EvaluationContext] the XSLT's evaluation
      #   context
      def initialize(s9_xslt_executable, evaluation_context)
        @s9_xslt_executable, @evaluation_context = s9_xslt_executable, evaluation_context
      end

      def_delegators :evaluation_context, :global_parameters, :initial_template_parameters, :initial_template_tunnel_parameters

      def apply_templates(source, opts = {})
        transformation(opts).apply_templates(source)
      end

      def call_template(template_name, opts = {})
        transformation(opts).call_template(template_name)
      end

      # @return [net.sf.saxon.s9api.XsltExecutable] the underlying Saxon
      #   <tt>XsltExecutable</tt>
      def to_java
        @s9_xslt_executable
      end

      private

      def transformation(opts)
        Transformation.new(params_merged_opts(opts).merge({
          s9_transformer: @s9_xslt_executable.load30,
        }))
      end

      def params_merged_opts(opts)
        merged_opts = params_hash.dup
        opts.each do |key, value|
          if [:global_parameters, :initial_template_parameters, :initial_template_tunnel_parameters].include?(key)
            merged_opts[key] = merged_opts.fetch(key, {}).merge(XSLT::ParameterHelper.process_parameters(value))
          else
            merged_opts[key] = value
          end
        end
        merged_opts
      end

      def params_hash
        @params_hash ||= begin
          params_hash = {}
          params_hash[:global_parameters] = global_parameters unless global_parameters.empty?
          params_hash[:initial_template_parameters] = initial_template_parameters unless initial_template_parameters.empty?
          params_hash[:initial_template_tunnel_parameters] = initial_template_tunnel_parameters unless initial_template_tunnel_parameters.empty?
          params_hash
        end.freeze
      end
    end

    class Result
      attr_reader :xdm_value

      def initialize(xdm_value, s9_transformer)
        @xdm_value, @s9_transformer = xdm_value, s9_transformer
      end

      def to_s
        serializer = Serializer.new(@s9_transformer.newSerializer)
        serializer.serialize(xdm_value.to_java)
      end
    end

    class Transformation
      attr_reader :s9_transformer, :opts

      def initialize(args)
        @s9_transformer = args.fetch(:s9_transformer)
        @destination = args.fetch(:destination, nil)
        @opts = args.reject { |opt, _|
          [:s9_transformer, :destination].include?(opt)
        }
        @raw = false
      end

      def apply_templates(source)
        transformation_result(:applyTemplates, source)
      end

      def call_template(template_name)
        transformation_result(:callTemplate, Saxon::QName.resolve(template_name))
      end

      private

      def transformation_result(invocation_method, invocation_arg)
        set_opts!
        transformer_args = [invocation_method, invocation_arg.to_java, destination].compact
        Result.new(result_xdm_value(s9_transformer.send(*transformer_args)), s9_transformer)
      end

      def result_xdm_value(transformer_return_value)
        XdmValue.wrap_s9_xdm_value(
          transformer_return_value.nil? ? destination.getXdmNode : transformer_return_value
        )
      end

      def destination
        @destination ||= begin
          Saxon::S9API::XdmDestination.new unless raw?
        end
      end

      def set_opts!
        opts.each do |opt, value|
          send(opt, value)
        end
      end

      def raw(value)
        @raw = value
      end

      def raw?
        @raw
      end

      def mode(mode_name)
        s9_transformer.setInitialMode(Saxon::QName.resolve(mode_name).to_java)
      end

      def global_parameters(parameters)
        s9_transformer.setStylesheetParameters(XSLT::ParameterHelper.to_java(parameters))
      end

      def initial_template_parameters(parameters)
        s9_transformer.setInitialTemplateParameters(XSLT::ParameterHelper.to_java(parameters) , false)
      end

      def initial_template_tunnel_parameters(parameters)
        s9_transformer.setInitialTemplateParameters(XSLT::ParameterHelper.to_java(parameters) , true)
      end
    end
  end
end