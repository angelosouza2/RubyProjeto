require 'httparty'

class MercadoPagoService
  include HTTParty
  base_uri 'https://api.mercadopago.com'

  def initialize(access_token)
    @headers = {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
    }
  end

  def create_payment(data)
    self.class.post("/v1/payments", headers: @headers, body: data.to_json)
  end

  def detect_payment_method(bin)
    Rails.logger.info "BIN do cartão: #{bin}"

    case bin
    when '503143'
      'master'
    when '423564'
      'visa'
    else
      begin
        response = self.class.get("/v1/payment_methods/search?bin=#{bin}&site_id=MLB", headers: @headers)
        payment_methods = JSON.parse(response.body)['results']

        if payment_methods.is_a?(Array) && payment_methods.any?
          payment_method_id = payment_methods.first['id']
          Rails.logger.info "Método de pagamento detectado: #{payment_method_id}"
          payment_method_id
        else
          Rails.logger.error "Nenhum método de pagamento encontrado para o BIN: #{bin}"
          nil
        end
      rescue StandardError => e
        Rails.logger.error "Erro ao detectar o método de pagamento: #{e.message}"
        nil
      end
    end
  end

  def generate_card_token(card_data)
    response = self.class.post("/v1/card_tokens", headers: @headers, body: card_data.to_json)
    token = JSON.parse(response.body)['id']
    Rails.logger.info "Token gerado com sucesso: #{token}"
    token
  rescue StandardError => e
    Rails.logger.error "Erro ao gerar o token do cartão: #{e.message}"
    nil
  end

  def handle_response(response)
    if response.code == 201
      {
        success: true,
        status: response['status'],
        status_detail: response['status_detail'],
        transaction_id: response['id'],
        payment_brand: response.dig('payment_method', 'id'),
        boleto_link: response.dig('transaction_details', 'external_resource_url'),
        ticket_url: response.dig('point_of_interaction', 'transaction_data', 'ticket_url')
      }
    else
      {
        success: false,
        error: response['message'] || 'Erro desconhecido'
      }
    end
  end
end
