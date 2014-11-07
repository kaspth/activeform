module ActiveForm
  class BackingForm
    include ActiveModel::Model

    delegate :persisted?, :to_model, :to_key, :to_param, :to_partial_path, to: :model

    class << self
      def build(model, options = {}, definition = nil)
        @model = model
        @options = options
        @associated_forms = {}
        instance_eval(&definition) if definition
      end
    end

    def add_association(name, options, block)
      form = @associated_forms.fetch(name) do
        self.class.build(name, options, block)
      end

      define_association_accessors(name, form)
    end

    def build_attributes(names, options = {})
      validates_presence_of(*names) if options[:required]

      names.each do |attr|
        delegate attr, "#{attr}=", to: :model
      end
    end

    def attributes=(params)
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end if params
    end

    def valid?
      super && @model.valid? && @associated_forms.each_value.all?(&:valid?)
    end

    def errors
      aggregate_errors
      super
    end

    private
      attr_reader :model

      def define_association_accessors(name, form)
        return unless respond_to?(name)

        define_method(name) { form }
        define_method("#{name}_attributes=") do |attrs|
          form.attributes = attrs
        end
      end

      def aggregate_errors
        @model.errors.each { |attr, e| errors.add(attr, e) }
        @associated_forms.each_value do |form|
          form.errors.each { |attr, e| errors.add(attr, e) }
        end
      end
  end
end
