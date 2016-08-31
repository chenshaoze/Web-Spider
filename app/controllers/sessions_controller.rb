class SessionsController < ApplicationController

	def new
		redirect_to root_path if current_user
		render :layout => 'empty'
	end

	def create
		user = User.find_by username: params[:username]
		if user && user.try(:authenticate, params[:password])
			session[:user_id] = user.id
			flash[:notice] = "欢迎使用新闻抓取系统"
		else
			flash[:error] = "用户名或密码错误, 请重试"
		end
		redirect_to root_path
	end

	def destroy
		session[:user_id] = nil
		flash[:notice] = "成功登出"
    redirect_to login_path
	end

	private
	def user_params
		params.require(:user).permit(:username, :password)
	end

end

