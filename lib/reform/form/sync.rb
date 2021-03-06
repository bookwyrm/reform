# #sync!
#   1. assign scalars to model (respecting virtual, excluded attributes)
#   2. call sync! on nested
module Reform::Form::Sync
  # Mechanics for writing input to model.
  # Writes input to model.
  module Writer
    def from_hash(*)
      # process output from InputRepresenter {title: "Mint Car", hit: <Form>}
      # and just call sync! on nested forms.
      nested_forms do |attr|
        attr.merge!(
          :instance     => lambda { |fragment, *| fragment },
          :deserialize => lambda { |object, *| model = object.sync! } # sync! returns the synced model.
          # representable's :setter will do collection=([..]) or property=(..) for us on the model.
        )
      end

      super
    end
  end

  # Transforms form input into what actually gets written to model.
  # output: {title: "Mint Car", hit: <Form>}
  module InputRepresenter
    include Reform::Representer::WithOptions
    # TODO: make dynamic.
    include Reform::Form::EmptyAttributesOptions
    include Reform::Form::ReadonlyAttributesOptions

    def to_hash(*)
      nested_forms do |attr|
        attr.merge!(
          :representable  => false,
          :prepare        => lambda { |obj, *| obj }
        )
      end

      super
    end
  end


  def sync_models
    sync!
  end
  alias_method :sync, :sync_models

  # reading from fields allows using readers in form for presentation
  # and writers still pass to fields in #validate????
  def sync! # semi-public.
    input_representer = mapper.new(fields).extend(InputRepresenter)

    input = input_representer.to_hash

    mapper.new(aliased_model).extend(Writer).from_hash(input) # sync properties to Song.

    model
  end
end
