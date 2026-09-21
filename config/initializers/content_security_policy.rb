# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    # The TelemetryDeck SDK is the only script served from another host. Its
    # beacons go to a different host and fall back to default_src.
    policy.script_src  :self, 'https://cdn.telemetrydeck.com'
    policy.style_src   :self
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate nonces for permitted importmap, inline scripts, and inline styles.
  # Rails' default derives the nonce from the session id, but this app never
  # writes to the session, so that would emit an empty and unusable nonce.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Automatically add `nonce` to `javascript_tag`, `javascript_include_tag`, and `stylesheet_link_tag`
  # if the corresponding directives are specified in `content_security_policy_nonce_directives`.
  # config.content_security_policy_nonce_auto = true

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
