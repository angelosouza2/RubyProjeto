class Admin::PaymentsController < ApplicationController
  before_action :authenticate_admin!

  def index
    if params[:query].present?
      @payments = Payment.where("LOWER(name) LIKE ? OR LOWER(email) LIKE ?", 
                                "%#{params[:query].downcase}%", 
                                "%#{params[:query].downcase}%")
                         .order(created_at: :desc)
                         .paginate(page: params[:page], per_page: 10)
    else
      @payments = Payment.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
    end

    # Verificação para evitar erros de `nil`
    if @payments.present?
      Rails.logger.info "Admin acessou a lista de pagamentos."
      Rails.logger.info "Total de pagamentos encontrados: #{@payments.count}"

      @payments.each do |payment|
        Rails.logger.info "Pagamento ID: #{payment.id}, Nome: #{payment.name}, Valor: #{payment.amount}, Status: #{payment.status}"
      end
    else
      Rails.logger.info "Nenhum pagamento encontrado."
    end
  end
end
