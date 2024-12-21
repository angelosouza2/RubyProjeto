class PaymentsController < ApplicationController
  def new
    @payment = Payment.new
  end

  def create
    service = MercadoPagoService.new(ENV['MERCADO_PAGO_ACCESS_TOKEN'])

    first_name, *last_name_parts = payment_params[:name].split(' ')
    last_name = last_name_parts.join(' ') if last_name_parts.any?

    payment_data = {
      transaction_amount: payment_params[:amount].to_f,
      description: 'Pagamento de Teste',
      payer: {
        email: payment_params[:email],
        first_name: first_name,
        last_name: last_name || 'Sobrenome'
      }
    }

    add_boleto_identification(payment_data) if payment_params[:payment_method] == 'bolbradesco'

    if payment_params[:payment_method] == 'credit_card'
      adjust_expiration_year

      if missing_card_fields?
        flash[:alert] = 'Todos os campos do cartão de crédito são obrigatórios.'
        render :new and return
      end

      payment_method_id = service.detect_payment_method(payment_params[:card_number][0..5])
      if payment_method_id.nil?
        flash[:alert] = 'Erro ao detectar a bandeira do cartão.'
        render :new and return
      end

      card_data = {
        card_number: payment_params[:card_number],
        expiration_month: payment_params[:card_expiration_month],
        expiration_year: payment_params[:card_expiration_year],
        security_code: payment_params[:security_code],
        cardholder: { name: payment_params[:card_holder_name] }
      }
      token = service.generate_card_token(card_data)
      if token.present?
        payment_data[:token] = token
        payment_data[:installments] = 1
        payment_data[:payment_method_id] = payment_method_id
      else
        flash[:alert] = 'Erro ao gerar o token do cartão de crédito.'
        render :new and return
      end
    else
      payment_data[:payment_method_id] = payment_params[:payment_method]
    end

    response = service.create_payment(payment_data)
    result = service.handle_response(response)

    if result[:success]
      Payment.create!(
        name: payment_params[:name],
        email: payment_params[:email],
        amount: payment_params[:amount],
        status: result[:status],
        transaction_id: result[:transaction_id],
        payment_method: payment_params[:payment_method]
      )

      redirect_to success_payments_path(
        name: payment_params[:name],
        amount: payment_params[:amount],
        transaction_id: result[:transaction_id],
        payment_method: payment_params[:payment_method],
        payment_brand: result[:payment_brand],
        boleto_link: result[:boleto_link],
        ticket_url: result[:ticket_url]
      ), notice: 'Pagamento realizado com sucesso!'
    else
      flash[:alert] = "Falha no pagamento: #{result[:error]}"
      render :new
    end
  end

  private

  def payment_params
    params.require(:payment).permit(
      :name, :email, :amount, :payment_method,
      :card_number, :card_expiration_month, :card_expiration_year,
      :security_code, :card_holder_name
    )
  end

  def missing_card_fields?
    payment_params[:card_number].blank? ||
    payment_params[:card_expiration_month].blank? ||
    payment_params[:card_expiration_year].blank? ||
    payment_params[:security_code].blank? ||
    payment_params[:card_holder_name].blank?
  end

  def adjust_expiration_year
    year = payment_params[:card_expiration_year]
    payment_params[:card_expiration_year] = "20#{year}" if year.present? && year.length == 2
  end

  def add_boleto_identification(payment_data)
    payment_data[:payer][:identification] = {
      type: 'CPF',
      number: '12345678909'
    }
  end
end
