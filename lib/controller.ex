defmodule Valspec.Controller do
  import Valspec.Utils

  @moduledoc """
  A module to conveniently generate valspec definitions within Phoenix controllers.

    ## Example

      defmodule MyAppWeb.ExampleUsersController do
        use MyAppWeb, :controller
        use Valspec.Controller

        valspec_create :create_user, summary: "Creates a User" do
          required(:first_name, :string, example: "Greg")
          required(:role, :enum, values: [:admin, :normal], default: :normal)
          optional(:last_name, :string, example: "Jones")
          optional(:age, :integer, minimum: 18)
        end

        def create(conn, params) do
              # `valspec_validate/2` - validates a map of parameters. Returns:
              #    - {:ok, map()} when params are valid
              #    - {:error, Ecto.%Changeset{}} when params are invalid
          with {:ok, user_params} <- valspec_validate(:create_user, params) do
            ...
          else
            {:error, %Ecto.Changeset{}} ->
              ...
          end
        end
      end


  # Options:
    * `tags`- the Swagger tags for the module. Example: [tags: ["V3 Clients Api"]].
    * `default_response_schema`- defines a default response schema for use in Swagger docs
    * `default_callback_schema`- defines a default callback schema for use in Swagger docs (Callbacks)
  """

  require OpenApiSpex

  defmacro __using__(opts) do
    quote do
      use OpenApiSpex.ControllerSpecs
      import Goal
      import Valspec.Utils
      import Valspec.Controller

      if opts_tags = Keyword.get(unquote(opts), :tags) do
        tags(opts_tags)
      end

      default_response_schema = Keyword.get(unquote(opts), :default_response_schema, nil)
      Module.put_attribute(__MODULE__, :default_response_schema, default_response_schema)

      default_callback_schema = Keyword.get(unquote(opts), :default_callback_schema, nil)
      Module.put_attribute(__MODULE__, :default_callback_schema, default_callback_schema)

      def valspec_validate(name, params) do
        validate_params(
          unquote(__CALLER__.module).schema(name),
          params
        )
      end
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
      open_api_opts = Keyword.get(unquote(opts), :open_api_opts, [])

      swagger_opts =
        [summary: summary, type: :object]
        |> maybe_add_response_schema(unquote(opts), @default_response_schema)
        |> maybe_add_open_api_opts(open_api_opts)

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
      open_api_opts = Keyword.get(unquote(opts), :open_api_opts, [])

      swagger_opts =
        [summary: summary, type: :object]
        |> maybe_add_response_schema(unquote(opts), @default_response_schema)
        |> maybe_add_open_api_opts(open_api_opts)

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
  Generates both a Goal validation struct and Swagger schema for a custom controller action.

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
      open_api_opts = Keyword.get(unquote(opts), :open_api_opts, [])

      swagger_opts =
        [summary: summary, type: :object]
        |> maybe_add_response_schema(unquote(opts), @default_response_schema)
        |> maybe_add_callback_schemas(unquote(opts), @default_callback_schema)
        |> maybe_add_open_api_opts(open_api_opts)

      operation(unquote(action), swagger_opts)
    end
  end

  defmacro valspec_custom(name, action, opts, do: expression) do
    new_module_name = generate_schema_module_name(__CALLER__.module, name)
    new_module = generate_new_schema_module(new_module_name, expression)

    quote do
      require OpenApiSpex

      # Goal...
      defparams unquote(name) do
        unquote(expression)
      end

      unquote(new_module)

      summary = Keyword.get(unquote(opts), :summary, "")
      open_api_opts = Keyword.get(unquote(opts), :open_api_opts, [])

      request_body =
        {"", "application/json", apply(unquote(Macro.escape(new_module_name)), :schema, [])}

      swagger_opts =
        [summary: summary, type: :object, request_body: request_body]
        |> maybe_add_response_schema(unquote(opts), @default_response_schema)
        |> maybe_add_callback_schemas(unquote(opts), @default_callback_schema)
        |> maybe_add_open_api_opts(open_api_opts)

      operation(unquote(action), swagger_opts)
    end
  end

  defp generate_new_schema_module(module, expr) do
    quote do
      defmodule unquote(module) do
        def schema do
          unquote(Macro.escape(generate_swagger_schema(expr)))
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

  defp generate_schema_module_name(module, name) do
    module
    |> Module.concat(Schemas)
    |> Module.concat(Macro.camelize(Atom.to_string(name)))
    |> Macro.escape()
  end
end
