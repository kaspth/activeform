module ActiveForm
  class Base
    include ActiveModel::ForbiddenAttributesProtection

    def initialize(model)
      @model = model

      @backing_form = BackingForm.new(model)
      associations.each { |a| @backing_form.add_association(a) }
      attribute_names.each do |(names, options)|
        @backing_form.build_attributes(names, options)
      end
    end

    delegate :to_model, :valid?, to: :backing_form

    def submit(params)
      @backing_form.attributes = sanitize_for_mass_assignment(params)
    end

    def save
      ActiveRecord::Base.transaction { model.save } if valid?
    end

    class << self
      attr_accessor :main_model

      def attributes(*names)
        attribute_names.push [names, names.extract_options!].compact
      end
      alias :attribute :attributes

      def association(name, options = {}, &block)
        associations << [name, options, block]
      end

      private
        def model_class
          @model_class ||= main_model.to_s.camelize.constantize
        end
    end

    private
      attr_reader :backing_form

      mattr_reader(:attribute_names) { [] }
      mattr_reader(:associations)    { [] }
  end
end
