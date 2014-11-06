require 'active_form/abstract_form'

module ActiveForm
  class Base < AbstractForm
    include ActiveModel::Model

    delegate :persisted?, :to_model, :to_key, :to_param, :to_partial_path, to: :model
    attr_reader :model

    def initialize(model)
      @model = model

      @forms = []
      populate_forms
    end

    def save
      return false unless valid?

      if ActiveRecord::Base.transaction { model.save }
        forms.each(&:reset)
      end
    end

    class << self
      attr_accessor :main_model
      delegate :reflect_on_association, to: :model_class

      def attributes(*names)
        options = names.pop if names.last.is_a?(Hash)

        if options && options[:required]
          validates_presence_of *names
        end

        names.each do |attribute|
          delegate attribute, "#{attribute}=", to: :model
        end
      end

      alias_method :attribute, :attributes

      def association(name, options = {}, &block)
        define_method(name) { instance_variable_get("@#{name}").models }
        define_method("#{name}_attributes=") {}

        forms << FormDefinition.new(name, block, options)
      end

      def forms
        @forms ||= []
      end

      private
        def model_class
          @model_class ||= main_model.to_s.camelize.constantize
        end
    end

    private

    def populate_forms
      self.class.forms.each do |definition|
        definition.parent = model
        definition.to_form.tap do |nested_form|
          forms << nested_form
          instance_variable_set("@#{definition.assoc_name}", nested_form)
        end
      end
    end
  end
end
