defmodule Valspec.Schema do
  @moduledoc """
  A module dedicated to generating Swagger schemas.

  See valspec_schema/1 for more information.
  """

  defmacro __using__(_opts) do
    quote do
      import Valspec.Schema
    end
  end

  @doc """
  Generates both an embedded_schema and a Swagger schema.

  ## Example:

      valspec_schema do
        field :id, :uuid, example: "82b557d1-0000-0000-0000-55df16add1b5"
        field :name, :string, example: "opts world"
        field :type, :enum, values: [:msp, :idn, :facility, :custom]
        field :account_id, :uuid
        field :location_id, :uuid
        field :updated_at, :utc_datetime
      end
  """
  @spec valspec_schema(do_block :: any()) :: Macro.t()
  defmacro valspec_schema(do: expression) do
    e_schema = Valspec.Utils.generate_embedded_schema(expression)
    s_schema = Valspec.Utils.generate_swagger_schema(expression)

    quote do
      use Ecto.Schema

      @primary_key false
      @derive {Jason.Encoder, except: []}
      embedded_schema do
        unquote(e_schema)
      end

      # Gets invoked within macros like valspec_create/3
      def __schema__ do
        unquote(Macro.escape(s_schema))
        # A single embedded_schema 'field' macro (field, embeds_one, embeds_many, etc.) may not
        # be passed in with a __block__ attribute, which is where we normally add the :type, and
        # :properties map needed to correctly generate the schema within generate_swagger_schema/1...
        |> then(fn maybe_schema ->
          if Map.has_key?(maybe_schema, :properties) do
            maybe_schema
          else
            %{:type => :object, :properties => maybe_schema}
          end
        end)
        |> OpenApiSpex.build_schema()
      end
    end
  end
end
