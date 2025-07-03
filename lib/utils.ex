defmodule Valspec.Utils do
  @schema_keys Map.keys(%OpenApiSpex.Schema{})

  @doc """
  Generates a OpenApiSpex.Schema.t() from a valspec definition.
  """
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

  defp maybe_update_opt_value_for_ast(opts, key) do
    if value = Keyword.get(opts, key) do
      # handle possible value passed as AST during compile
      {updated_value, _} = Code.eval_quoted(value)
      Keyword.replace(opts, key, updated_value)
    else
      opts
    end
  end

  # inspired by how ecto schema handles aliases within a schema.
  defp expand_nested_module_alias({:__aliases__, _, [Elixir, _ | _] = alias}, _env),
    do: Module.concat(alias)

  defp expand_nested_module_alias({:__aliases__, _, [h | t]}, _env) when is_atom(h),
    do: Module.concat([h | t])

  defp expand_nested_module_alias(other, _env), do: other

  @doc """
  Generates a Ecto.Schema.t() from a valspec definition.
  """
  def generate_embedded_schema({:__block__, _lines, contents}) do
    Enum.reduce(contents, [], fn function, acc ->
      [generate_embedded_schema(function) | acc]
    end)
  end

  # translate swagger uuid -> ecto string
  def generate_embedded_schema({:field, lines, [field, :uuid]}),
    do: {:field, lines, [field, :string]}

  def generate_embedded_schema({:field, lines, [field, :uuid, _opts]}),
    do: {:field, lines, [field, :string]}

  # translate swagger enum -> ecto string
  def generate_embedded_schema({:field, lines, [field, :enum]}),
    do: {:field, lines, [field, :string]}

  def generate_embedded_schema({:field, lines, [field, :enum, _opts]}),
    do: {:field, lines, [field, :string]}

  def generate_embedded_schema({:field, lines, [field, type]}),
    do: {:field, lines, [field, type]}

  def generate_embedded_schema({:field, lines, [field, type, _opts]}),
    do: {:field, lines, [field, type]}

  def generate_embedded_schema(anything), do: anything

  def add_callback_schema(callback_schema_module) do
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

  def maybe_add_callback_schemas(base_opts, opts, default \\ nil) do
    if callback_schema_modules = Keyword.get(opts, :callback_schemas) || default do
      callbacks =
        [callback_schema_modules]
        |> List.flatten()
        |> Enum.reduce(%{}, fn callback_schema_module, acc ->
          val = add_callback_schema(callback_schema_module)
          Map.merge(acc, val)
        end)

      Keyword.merge(base_opts, callbacks: callbacks)
    else
      base_opts
    end
  end
end
