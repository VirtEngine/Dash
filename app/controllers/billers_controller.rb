class BillersController < ApplicationController
    include CurrentBilly
    include LaunchableAssembler
    include LaunchedBiller

    SHOPPER_PROCESSE = 'Shopper'.freeze
    ORDERER_PROCESSE = 'Orderer'.freeze

    before_action :add_authkeys_for_api, only: [:show, :create]


    def show
        render json: {shopper: shopper || {} , regions: regions}
    end

    def create
        addon = lookup_external_id_in_addons(params)
      if addon[:result] == 'success'
        render json: { success: true , whmcsurl: order(addon[:external_id].merge(params), params[:email]) || {}}
      else
          render json: {error: I18n.t("billing.error")}
      end
    end


    def order_created
        if sub =   Api::Subscriptions.new.create(params)
            render json: success_json
        else
            render json: {error: I18n.t("login.incorrect_email_or_password")}
        end
    end


    private

    def invalid_credentials
        render json: {error: I18n.t("errors.not_onboarded_in_biller")}
    end

    def shopper

        l = lookup_external_id_in_addons(params)
        if bildr = bildr_processe_is_ready(SHOPPER_PROCESSE)
            {productsdetail:   b = bildr.new.shop(l), payments: bildr.new.after_shop(b)}
        else
        invalid_credentials
        end
    end

    def order(addon, email)
        if bildr = bildr_processe_is_ready(ORDERER_PROCESSE)
            b = bildr.new.order(addon || {})
            bildr.new.after_order(b, email)
          else
          invalid_credentials
        end
    end

    def bildr_processe_is_ready(processe)
        bildr = Biller::Builder.new(processe)
        return unless bildr.implementation
        bildr.implementation

    end
end
