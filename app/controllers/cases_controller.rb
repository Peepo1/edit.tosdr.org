class CasesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_curator, only: [:destroy]
  before_action :set_case, only: [:show, :edit, :update, :destroy]

  def index
    @topics = Topic.includes(:cases).all
    if params[:query]
      @topics = @topics.search_by_topic_title(params[:query])
    end
  end

  def new
    @case = Case.new
  end

  def edit
  end

  def create
    @case = Case.new(case_params)
    if @case.save
      redirect_to case_path(@case)
    else
      render :new
    end
  end

  def show
    @points = @case.points.includes(:service).includes(:user)
    if params[:query]
      @points = @points.search_points_by_multiple(params[:query]).where(case: @case)
    elsif params[:status] && ['declined', 'pending', 'approved', 'changes-requested'].include?(params[:status])
      @points = @points.where(case: @case, status: params[:status])
    end
  end

  def update
    @case.update(case_params)
    flash[:notice] = "Case has been updated!"
    redirect_to case_path(@case)
  end

  def destroy
    if @case.points.any?
      flash[:alert] = "Users have contributed valuable insight to this case!"
      redirect_to case_path(@case)
    else
      @case.destroy
      flash[:notice] = "Case has been deleted!"
      redirect_to cases_path
    end
  end

  private
  def set_case
    @case = Case.find(params[:id])
  end

  def case_params
    params.require(:case).permit(:classification, :score, :title, :description, :topic_id, :privacy_related)
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end

end
