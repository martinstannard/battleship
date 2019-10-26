defmodule Noder.Game do
  @moduledoc """
  Implement your game here
  """

  def call(state) do
    {:rand.uniform(20) - 1, :rand.uniform(80) - 1}
    # :rand.uniform(length(state)) - 1
  end
end
