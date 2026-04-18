# frozen_string_literal: true

class PublicExerciseRoutinesController < ApplicationController
  def index
    @routines = ExerciseRoutine.where(publicly_shareable: true).order(:name)
  end

  def show
    @routine = ExerciseRoutine.find_by!(publicly_shareable: true, id: params[:id])
  end
end
