defmodule MyAppWeb.UsersController do
  use MyAppWeb, :controller

  use Valspec.Controller,
    tags: ["Users"],
    default_callback_schema: MyApp.Users.CallbackSchema,
    default_response_schema: MyApp.Users.JSONResponse

  valspec_create :create_user, summary: "Creates a user" do
    required(:first_name, :string, description: "first name of the user")
    required(:age, :integer, minimum: 20)
    optional(:last_name, :string)
  end

  def create(conn, params) do
    with {:ok, _} <- valspec_validate(:create_user, params) do
      conn
      |> put_status(200)
      |> json(%{})
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        errors = validation_errors(changeset)

        conn
        |> put_status(400)
        |> json(%{errors: errors})
    end
  end

  valspec_update :update_user, summary: "Updates a user", open_api_opts: [
    parameters: [
      id: [in: :path, description: "User ID", type: :integer, example: 1001]
    ]
  ] do
    required(:first_name, :string, nullable: false)
    required(:age, :integer, minimum: 20)
    optional(:last_name, :string)
  end

  def update(conn, params) do
    with {:ok, _} <- valspec_validate(:update_user, params) do
      conn
      |> put_status(200)
      |> json(%{})
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        errors = validation_errors(changeset)

        conn
        |> put_status(400)
        |> json(%{errors: errors})
    end
  end

  valspec_index(
    summary: "Lists all users",
    response_schema: MyApp.Users.JSONIndexResponse
  )

  def index(conn, _) do
    conn
  end

  valspec_show(summary: "Lists a single user")

  def show(conn, _) do
    conn
  end

  valspec_delete(summary: "Deletes a user")

  def delete(conn, _) do
    conn
  end

  def validation_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
