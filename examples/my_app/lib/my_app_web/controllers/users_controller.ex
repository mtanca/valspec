defmodule MyAppWeb.UsersController do
  use MyAppWeb, :controller

  use Valspec,
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
      put_status(conn, 200)
    else
      _ ->
        put_status(conn, 400)
    end
  end

  valspec_update :updates_user, summary: "Updates a user" do
    required(:first_name, :string, nullable: false)
    required(:age, :integer, minimum: 20)
    optional(:last_name, :string)
  end

  def update(conn, params) do
    with {:ok, _} <- valspec_validate(:update_user, params) do
      put_status(conn, 200)
    else
      _ ->
        put_status(conn, 400)
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
end
