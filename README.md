# Valspec

**An elixir library for Phoenix that generates Swagger documentation and performs parameter validation.**

## Installation

The latest version of Valspec is built on top [open_api_spex](https://github.com/open-api-spex/open_api_spex). You will need to install it along with the Valspec dependency:

```elixir
def deps do
  [
    {:open_api_spex, "~> 3.21"},
    {:valspec, "~> 0.2.0"}
  ]
end
```

## Adding to your project

### Define your spec

The first thing you will need to do is define your `open_api_spex` spec definition.
Visit the [Generate Spec](https://github.com/open-api-spex/open_api_spex?tab=readme-ov-file#generate-spec) section in the github repo for more information.

### Serving your spec (Running Swagger UI)
Visit the [Serve Spec](https://github.com/open-api-spex/open_api_spex?tab=readme-ov-file#serve-the-spec) section in the github repo for more information on how to run the UI.

### Add Valspec to your controller
```elixir
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
        {:error, %Ecto.Changeset{} = _changeset} ->
          ...
      end
    end
  end
```

### Creating a schema
Using `valspex_schema/1` allows you to define response or callback schemas for your documentation. `valspex_schema/1` uses Ecto `embedded_schema` under the hood and uses its
syntax:

```elixir
  defmodule MyAppWeb.Users.Schema do
    use Valspec.Schema

    valspec_schema do
      field :id, :uuid, example: "82b557d1-0000-0000-0000-55df16add1b5"
      field :first_name, :string, example: "Greg"
      field :last_name, :string, example: "Jones"
      field :role, :enum, values: [:admin, :normal]
      field :age, :integer
    end
  end

  # You can use a valspec schema within other valspec schemas via `embeds_one/2` 
  # or `embeds_many/2`
  defmodule MyApp.Users.SucessResponse do
    use Valspec.Schema

    valspec_schema do
      embeds_one :data, MyAppWeb.Users.Schema
    end
  end
```

You can use the schema by using the `default_response_schema` opt on init or by passing the `response_schema` to the valspec operation:

```elixir
  defmodule MyAppWeb.ExampleUsersController do
    use MyAppWeb, :controller
    use Valspec.Controller,
    # Applies to all actions unless overridden
    default_response_schema: MyApp.Users.SucessResponse
    
    # Uses MyApp.Users.SucessResponse
    valspec_create :create_user, summary: "Creates a User" do
      required(:first_name, :string, example: "Greg", nullable: true)
    end

    valspec_update 
      :update_user, 
      summary: "Updates a User"
      # Overrides default MyApp.Users.SucessResponse
      response_schema: MyApp.Users.UpdateSucessResponse do
      required(:first_name, :string, example: "Greg")
    end
  end
```


### Using schemas for type safety
You can use your schemas directly in your responses to ensure your documentation is always up-to-date like so:

```elixir
defmodule MyAppWeb.ExampleUsers.JSON do 
  def create(%{user: user}) do
    %MyApp.Users.SucessResponse{data: data(user)}
  end

  defp data(%User{} = user) do
    %MyAppWeb.Users.Schema{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      age: user.age
    }
  end
end
```

## List of operations
  The following macros are exposed:

  * `valspec_create/3`- define specs for a controller's #create/2 action
  * `valspec_update/3`- define specs for a controller's #update/2 action
  * `valspec_index/1` - define specs for a controller's #index/2 action
  * `valspec_delete/1` - define specs for a controller's #delete/2 action
  * `valspec_show/1` - define specs for a controller's #show/2 action
  * `valspec_custom/2` - define specs for a custom controller action.
  * `valspec_custom/4` - define specs for a custom controller action.
  * `valspec_schema/1`- defines a struct that can used in defining responses and callbacks.
  * `valspec_validate/2` - validates a map of parameters.
    Returns:
      - `{:ok, map()}` when params are valid
      - `{:error, Ecto.%Changeset{}}` when params are invalid

  ## Examples
  There is an example phoenix project in this repo under `/examples/my_app`. You can run the app and navigate to the `/swaggerui#` to see the example
