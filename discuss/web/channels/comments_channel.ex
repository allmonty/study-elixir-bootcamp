defmodule Discuss.CommentsChannel do
  use Discuss.Web, :channel

  alias Discuss.{Topic, Comment}

  def join("comments:" <> topic_id, _params, socket) do
    topic_id = String.to_integer(topic_id)
    topic = Topic
      |> Repo.get(topic_id)
      |> Repo.preload(comments: [:user])

    {:ok, %{comments: topic.comments}, assign(socket, :topic, topic)}
  end

  def handle_in(name, %{"content" => content}, socket) do
    topic = socket.assigns.topic

    # The course says to use ===> user_id = socket.assigns.user_id
    # But this version won't work well
    # It will crash if nothing were assigned
    # The way bellow is the correct way, that will return teh value or nil
    user_id = socket.assigns[:user_id]

    changeset = topic
      |> build_assoc(:comments, user_id: user_id)
      |> Comment.changeset(%{content: content})
    
    case Repo.insert(changeset) do
      {:ok, comment} ->
        comment = Repo.preload(comment, :user)
        broadcast!(socket, "comments:#{socket.assigns.topic.id}:new", %{comment: comment})
        {:reply, :ok, socket}

      {:error, _reason} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end
end