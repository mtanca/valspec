defmodule Valspec do
  @moduledoc """

  # Options:
    * `tags`- the Swagger tags for the module. Example: [tags: ["V3 Clients Api"]].
    * `default_response_schema`- defines a default response schema for use in Swagger docs
    * `default_callback_schema`- defines a default callback schema for use in Swagger docs (Callbacks)
  """

  require OpenApiSpex
  @schema_keys Map.keys(%OpenApiSpex.Schema{})

  defmacro __using__(opts) do
    quote do
      use OpenApiSpex.ControllerSpecs
      import Goal
      import Valspec

      if opts_tags = Keyword.get(unquote(opts), :tags) do
        tags(opts_tags)
      end

      default_response_schema = Keyword.get(unquote(opts), :default_response_schema, nil)
      Module.put_attribute(__MODULE__, :default_response_schema, default_response_schema)

      default_callback_schema = Keyword.get(unquote(opts), :default_callback_schema, nil)
      Module.put_attribute(__MODULE__, :default_callback_schema, default_callback_schema)
    end
  end

  @doc """
  Generates both a Goal validation struct and Swagger schema for a create controller action.

  Example:

      valspec_create :create_client,
      summary: "Creates a client",
      response_schema: MyAppWeb.Response do
        required(:name, :string, example: "Client 1")
        required(:type, :enum, values: [:vendor, :customer])
        required(:account_id, :uuid, example: "82b557d1-c529-4aff-b0fb-55df16add1b5")
      end

  # Options:
    * `summary`- a summary of what the post request does.
    * `response_schema`- a response schema defined with the valspec_schema macro.
    * `callback_schemas`- a list of tuples with the name of a callback to a schema. Example:
      `
      [{"Create User Webhook", MyApp.User.WebhookSchema}, {"Create Account Webhook", MyApp.User.WehookSchema}]
      `
  """
  @spec valspec_create(name :: String.t(), opts :: Keyword.t(), block :: any()) :: Macro.t()
  defmacro valspec_create(name, opts, do: expression) do
    quote do
      valspec_custom(
        unquote(name),
        :create,
        unquote(opts),
        do: unquote(expression)
      )
    end
  end

  @doc """
  Generates both a Goal validation struct and Swagger schema for an update controller action.

  Example:

      valspec_update :update_client,
        summary: "Updates a client",
        response_schema: MyAppWeb.Response do
        optional(:client_id, :uuid, example: "82b557d1-c529-4aff-b0fb-55df16add1b5")

        optional(:location_id, :string,
          format: "uuid",
          example: "b388a4da-a3d6-42d4-8a98-4149f0007e6b",
          description: "the location_id used to do stuff..."
        )
      end

  # Options:
    * `summary`- a summary of what the post request does.
    * `response_schema`- a response schema defined with the valspec_schema macro.
    * `callback_schemas`- a list of tuples with the name of a callback to a schema. Example:
      `
      [{"Update User Webhook", MyApp.User.WebhookSchema}, {"Update Account Webhook", MyApp.User.WehookSchema}]
      `
  """
  @spec valspec_update(name :: String.t(), opts :: Keyword.t(), block :: any()) :: Macro.t()
  defmacro valspec_update(name, opts, do: expression) do
    quote do
      valspec_custom(
        unquote(name),
        :update,
        unquote(opts),
        do: unquote(expression)
      )
    end
  end

  @doc """
  Generates both a Goal validation struct and Swagger schema for an index controller action.

  Example:

      valspec_index(
        summary: "Lists all clients",
        response_schema:  MyAppWeb.IndexResponse,
      )

  # Options:
    * `summary`- a summary of what the post request does.
    * `response_schema`- a response struct defined with the valspec_schema macro.
  """
  @spec valspec_index(opts :: Keyword.t()) :: Macro.t()
  defmacro valspec_index(opts) do
    quote do
      require OpenApiSpex

      summary = Keyword.get(unquote(opts), :summary, "")

      swagger_opts =
        [summary: summary, type: :object]
        |> maybe_add_response_schema(unquote(opts), @default_response_schema)

      operation(:index, swagger_opts)
    end
  end

  @doc """
  Generates both a Goal validation struct and Swagger schema for a show controller action.

  Example:

      valspec_show(
        summary: "Show a single client",
        response_schema: MyAppApi.V3.Client.JSON.IndexResponse
      )

  # Options:
    * `summary`- a summary of what the post request does.
    * `response_schema`- a response struct defined with the valspec_schema macro.
  """
  defmacro valspec_show(opts) do
    quote do
      require OpenApiSpex

      summary = Keyword.get(unquote(opts), :summary, "")

      swagger_opts =
        [summary: summary, type: :object]
        |> maybe_add_response_schema(unquote(opts), @default_response_schema)

      operation(:show, swagger_opts)
    end
  end

  @doc """
    Generates both a Goal validation struct and Swagger schema for a delete controller action.

    ## Example:

        valspec_delete(
          summary: "Deletes a client",
          response_schema: MyAppWeb.Response
        )

    ## Options:

    * `summary` - Swagger endpoint summary
    * `response_schema` - The schema module to generating the response schema
    * `callback_schemas`- a list of tuples with the name of a callback to a schema. Example:
      `
      [{"Delete User Webhook", MyApp.User.WebhookSchema}, {"Delete Account Webhook", MyApp.User.WehookSchema}]
      `
  """
  @spec valspec_delete(opts :: Keyword.t()) :: Macro.t()
  defmacro valspec_delete(opts) do
    quote do
      valspec_custom(:delete, unquote(opts))
    end
  end

  @doc """

    ## Example 1:

        valspec_custom(:my_action, summary: "Hello world")

    ## Example 2:

        valspec_custom
          :my_validation_name
          :my_action,
          summary: "Hello world" do
              required(:id, :string)
              optional(:name, :string)
              optional(:location_id, :string,
                  format: "uuid",
                  example: "b388a4da-a3d6-42d4-8a98-4149f0007e6b",
                  description: "the location_id of something..."
              )
        end

    ## Options:

    * `summary` - Swagger endpoint summary
    * `response_schema` - The schema module to generating the response schema
  """
  @spec valspec_custom(
          name :: atom(),
          action :: atom(),
          opts :: Keyword.t(),
          block :: any()
        ) :: Macro.t()
  defmacro valspec_custom(action, opts) do
    quote do
      require OpenApiSpex

      summary = Keyword.get(unquote(opts), :summary, "")

      swagger_opts =
        [summary: summary, type: :object]
        |> maybe_add_response_schema(unquote(opts), @default_response_schema)
        |> maybe_add_callback_schemas(unquote(opts), @default_callback_schema)

      operation(unquote(action), swagger_opts)
    end
  end

  defmacro valspec_custom(name, action, opts, do: expression) do
    new_module_name = generate_schema_module_name(__CALLER__.module, name)

    quote do
      require OpenApiSpex

      # Goal...
      defparams unquote(name) do
        unquote(expression)
      end

      unquote(generate_new_schema_module(Macro.escape(new_module_name), expression))

      summary = Keyword.get(unquote(opts), :summary, "")

      request_body =
        {"", "application/json", apply(unquote(Macro.escape(new_module_name)), :schema, [])}

      swagger_opts =
        [summary: summary, type: :object, request_body: request_body]
        |> maybe_add_response_schema(unquote(opts), @default_response_schema)
        |> maybe_add_callback_schemas(unquote(opts), @default_callback_schema)

      operation(unquote(action), swagger_opts)

      def valspec_validate(name, params) do
        validate_params(
          unquote(__CALLER__.module).schema(name),
          params
        )
      end
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
    quote do
      use Ecto.Schema

      @primary_key false
      @derive {Jason.Encoder, except: []}
      embedded_schema do
        unquote(generate_embedded_schema(expression))
      end

      # Gets invoked within macros like valspec_create/3
      def __schema__ do
        unquote(Macro.escape(generate_swagger_schema(expression)))
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

  # ------ PRIVATE -----
  def generate_swagger_schema({:__block__, _, contents}) do
    %{
      type: :object,
      properties:
        Enum.reduce(contents, %{}, fn function, acc ->
          Map.merge(acc, generate_swagger_schema(function))
        end)
    }
  end

  # Support embedded_schema definitions within Swagger
  def generate_swagger_schema({:embeds_many, _lines, [field, {:__aliases__, _, _} = als]}) do
    schema = expand_nested_module_alias(als, Macro.Env.location(__ENV__))
    opts = [type: :array, items: schema.__schema__()]

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  def generate_swagger_schema({:embeds_one, _lines, [field, {:__aliases__, _, _} = als]}) do
    schema = expand_nested_module_alias(als, Macro.Env.location(__ENV__))

    %{field => schema.__schema__()}
  end

  # Support Goals :uuid type within Swagger
  def generate_swagger_schema({maybe_required, _lines, [field, :uuid, opts]}) do
    opts = maybe_update_opt_value_for_ast(opts, :example)

    opts =
      Enum.into(opts, %{})
      |> Map.take(@schema_keys)
      |> Map.put(:type, :string)
      |> Map.put(:format, "uuid")
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  def generate_swagger_schema({maybe_required, _lines, [field, :uuid]}) do
    opts =
      %{}
      |> Map.put(:type, :string)
      |> Map.put(:format, "uuid")
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  # Support Ectos :utc_datetime type within Swagger
  def generate_swagger_schema({maybe_required, _lines, [field, :utc_datetime, opts]}) do
    opts =
      opts
      #  date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z
      |> Keyword.put_new(:example, "2024-08-12T21:00:39")
      |> maybe_update_opt_value_for_ast(:example)
      # ensure example is always a string
      |> Keyword.update!(:example, fn example -> to_string(example) end)
      |> Enum.into(%{})
      |> Map.take(@schema_keys)
      |> Map.put(:type, :string)
      |> Map.put(:format, "date-time")
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  def generate_swagger_schema({maybe_required, _lines, [field, :utc_datetime]}) do
    opts =
      %{}
      |> Map.put(:type, :string)
      |> Map.put(:format, "date-time")
      #  date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z
      |> Map.put(:example, "2024-08-12T21:00:39")
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  # Support Ectos :naive_datetime type within Swagger
  def generate_swagger_schema({maybe_required, _lines, [field, :naive_datetime, opts]}) do
    opts =
      opts
      #  date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z
      |> Keyword.put_new(:example, "2024-08-12T21:00:39")
      |> maybe_update_opt_value_for_ast(:example)
      # ensure example is always a string
      |> Keyword.update!(:example, fn example -> to_string(example) end)
      |> Enum.into(%{})
      |> Map.take(@schema_keys)
      |> Map.put(:type, :string)
      |> Map.put(:format, "date-time")
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  def generate_swagger_schema({maybe_required, _lines, [field, :naive_datetime]}) do
    opts =
      %{}
      |> Map.put(:type, :string)
      |> Map.put(:format, "date-time")
      #  date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z
      |> Map.put(:example, "2024-08-12T21:00:39")
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  # Support Ectos :date type within Swagger
  def generate_swagger_schema({maybe_required, _lines, [field, :date, opts]}) do
    opts = maybe_update_opt_value_for_ast(opts, :example)

    opts =
      opts
      |> then(fn opts ->
        if Keyword.has_key?(opts, :example) do
          Keyword.replace(opts, :example, to_string(opts[:example]))
        else
          opts
        end
      end)
      |> Keyword.replace(:example, to_string(opts[:example] || ""))
      |> Enum.into(%{})
      |> Map.take(@schema_keys)
      |> Map.put(:type, :string)
      |> Map.put(:format, "date")
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  def generate_swagger_schema({maybe_required, _lines, [field, :date]}) do
    opts =
      %{}
      |> Map.put(:type, :string)
      |> Map.put(:format, "date")
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  # Support Goals :enum type within Swagger
  def generate_swagger_schema({maybe_required, _lines, [field, :enum, opts]}) do
    opts = maybe_update_opt_value_for_ast(opts, :values)

    opts =
      opts
      |> Keyword.put_new(:enum, Enum.map(opts[:values], &to_string/1))
      |> Enum.into(%{})
      |> Map.take(@schema_keys)
      |> Map.put(:type, :string)
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  # Support Goals :decimal type within Swagger
  def generate_swagger_schema({maybe_required, _lines, [field, :decimal]}) do
    opts = %{type: :number, format: "double", required: maybe_required == :required}
    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  def generate_swagger_schema({maybe_required, _lines, [field, :decimal, opts]}) do
    opts =
      opts
      |> maybe_update_opt_value_for_ast(:example)
      |> maybe_update_opt_value_for_ast(:minimum)
      |> maybe_update_opt_value_for_ast(:maximum)
      |> then(fn opts ->
        example = Keyword.get(opts, :example)
        minimum = Keyword.get(opts, :minimum)
        maximum = Keyword.get(opts, :maximum)

        [example, minimum, maximum]
        |> Enum.filter(& &1)
        |> Enum.reduce(opts, fn value, acc ->
          case value do
            %Decimal{} ->
              raise """
              Do not use Decimal module with valspec. Value: #{inspect(value)}
              """

            _ ->
              nil
          end

          acc
        end)
      end)
      |> Enum.into(%{})
      |> Map.take(@schema_keys)
      |> Map.put(:type, :number)
      |> Map.put(:format, "double")
      |> Map.put(:required, maybe_required == :required)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  # Support Goals {:array, type} type within Swagger
  def generate_swagger_schema({maybe_required, _lines, [field, {:array, subtype}, opts]}) do
    # Case where subtype == :map
    if do_block = Keyword.get(opts, :do) do
      nested_schema = generate_swagger_schema(do_block)

      nested_schema =
        if Map.has_key?(nested_schema, :properties),
          do: nested_schema,
          else: %{properties: nested_schema}

      opts = [
        type: :array,
        items: %OpenApiSpex.Schema{
          type: :object,
          properties: nested_schema.properties,
          required: maybe_required == :required
        }
      ]

      %{field => struct(OpenApiSpex.Schema, opts)}
    else
      if subtype not in [:string, :integer], do: "Unsuported subtype #{inspect(subtype)} in array"

      base_opts = maybe_update_opt_value_for_ast(opts, :example)

      opts =
        [
          type: :array,
          items: %OpenApiSpex.Schema{type: subtype, required: maybe_required == :required}
        ]
        |> Keyword.merge(base_opts)
        |> Enum.into(%{})
        |> Map.take(@schema_keys)

      %{field => struct(OpenApiSpex.Schema, opts)}
    end
  end

  def generate_swagger_schema({maybe_required, _lines, [field, {:array, subtype}]}) do
    if subtype not in [:string, :integer], do: "Unsuported subtype #{inspect(subtype)} in array"

    opts =
      [
        type: :array,
        items: %OpenApiSpex.Schema{type: subtype, required: maybe_required == :required}
      ]
      |> Enum.into(%{})
      |> Map.take(@schema_keys)

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  # Support Goals :map type within Swagger
  def generate_swagger_schema({maybe_required, _lines, [field, :map, opts]}) do
    # Case where subtype == :map
    if do_block = Keyword.get(opts, :do) do
      nested_schema = generate_swagger_schema(do_block)

      opts = [
        type: :object,
        properties: nested_schema.properties,
        required: maybe_required == :required
      ]

      %{field => struct(OpenApiSpex.Schema, opts)}
    else
      %{field => struct(OpenApiSpex.Schema, type: :object, required: maybe_required == :required)}
    end
  end

  def generate_swagger_schema({maybe_required, _lines, [field, type]}) do
    opts = %{type: type, required: maybe_required == :required}
    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  # maybe translate Goal string w/ includes into Swagger enum
  def generate_swagger_schema({maybe_required, _lines, [field, :string, opts]}) do
    if Keyword.has_key?(opts, :included) do
      # handle possible included passed as AST during compile
      {updated_included, _} = Code.eval_quoted(opts[:included])
      opts = Keyword.put(opts, :values, updated_included)
      generate_swagger_schema({maybe_required, nil, [field, :enum, opts]})
    else
      opts = maybe_update_opt_value_for_ast(opts, :example)

      opts =
        Enum.into(opts, %{})
        |> Map.take(@schema_keys)
        |> Map.put(:type, :string)
        |> Map.put(:required, maybe_required == :required)

      %{field => struct(OpenApiSpex.Schema, opts)}
    end
  end

  def generate_swagger_schema({maybe_required, _lines, [field, type, opts]}) do
    opts =
      Enum.into(opts, %{})
      |> Map.take(@schema_keys)
      |> Map.put(:type, type)

    opts = if maybe_required == :required, do: Map.put(opts, :required, true), else: opts

    %{field => struct(OpenApiSpex.Schema, opts)}
  end

  def generate_swagger_schema({_type, _lines, _contents}) do
    %{}
  end

  defp generate_embedded_schema({:__block__, _lines, contents}) do
    Enum.reduce(contents, [], fn function, acc ->
      [generate_embedded_schema(function) | acc]
    end)
  end

  # translate swagger uuid -> ecto string
  defp generate_embedded_schema({:field, lines, [field, :uuid]}),
    do: {:field, lines, [field, :string]}

  defp generate_embedded_schema({:field, lines, [field, :uuid, _opts]}),
    do: {:field, lines, [field, :string]}

  # translate swagger enum -> ecto string
  defp generate_embedded_schema({:field, lines, [field, :enum]}),
    do: {:field, lines, [field, :string]}

  defp generate_embedded_schema({:field, lines, [field, :enum, _opts]}),
    do: {:field, lines, [field, :string]}

  defp generate_embedded_schema({:field, lines, [field, type]}),
    do: {:field, lines, [field, type]}

  defp generate_embedded_schema({:field, lines, [field, type, _opts]}),
    do: {:field, lines, [field, type]}

  defp generate_embedded_schema(anything), do: anything

  # inspired by how ecto schema handles aliases within a schema.
  defp expand_nested_module_alias({:__aliases__, _, [Elixir, _ | _] = alias}, _env),
    do: Module.concat(alias)

  defp expand_nested_module_alias({:__aliases__, _, [h | t]}, _env) when is_atom(h),
    do: Module.concat([h | t])

  defp expand_nested_module_alias(other, _env), do: other

  def add_callback_schema_for(callback_schema_module) do
    schema = callback_schema_module.__schema__()

    req_body = %OpenApiSpex.Operation{
      requestBody: %OpenApiSpex.RequestBody{
        content: %{
          "application/json" => %OpenApiSpex.MediaType{
            schema: schema
          }
        }
      },
      responses: %{
        200 => %OpenApiSpex.Response{
          description: "Your server returns this code if it accepts the callback"
        }
      }
    }

    %{
      "#{schema.title}" => %{
        "" => %OpenApiSpex.PathItem{post: req_body}
      }
    }
  end

  defp maybe_update_opt_value_for_ast(opts, key) do
    if value = Keyword.get(opts, key) do
      # handle possible value passed as AST during compile
      {updated_value, _} = Code.eval_quoted(value)
      Keyword.replace(opts, key, updated_value)
    else
      opts
    end
  end

  @doc """
  Creates AST to generate a new swagger schema module.

  The AST gets unquoted inside a `valspec_` macro.

  Currently, used to generate a new Swagger Request Schema module.
  """
  def generate_new_schema_module(module, expr) do
    quote do
      defmodule unquote(module) do
        def schema do
          unquote(Valspec.generate_swagger_schema(expr) |> Macro.escape())
          # A single schema 'field' macro (field, embeds_one, embeds_many, etc.) may not
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

  @doc """
  Helper to generate a new module name for the Swagger schema based on the current
  module the macro is being expanded in.
  """
  def generate_schema_module_name(module, name) do
    module
    |> Module.concat(Schemas)
    |> Module.concat(Macro.camelize(Atom.to_string(name)))
    |> Macro.escape()
  end

  @doc """
  Helper to possibly add the response schema opt to the Swagger operation
  """
  def maybe_add_response_schema(base_opts, opts, default \\ nil) do
    if response_schema = Keyword.get(opts, :response_schema) || default do
      Keyword.merge(base_opts,
        responses: %{201 => {"", "application/json", response_schema.__schema__()}}
      )
    else
      base_opts
    end
  end

  @doc """
  Helper to possibly add the callback schemas opt to the Swagger operation
  """
  def maybe_add_callback_schemas(base_opts, opts, default \\ nil) do
    if callback_schema_modules = Keyword.get(opts, :callback_schemas) || default do
      callbacks =
        [callback_schema_modules]
        |> List.flatten()
        |> Enum.reduce(%{}, fn callback_schema_module, acc ->
          val = add_callback_schema_for(callback_schema_module)

          Map.merge(acc, val)
        end)

      Keyword.merge(base_opts, callbacks: callbacks)
    else
      base_opts
    end
  end
end
