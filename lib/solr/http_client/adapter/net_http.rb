require 'net/http'

class Solr::HTTPClient::Adapter::NetHTTP
  
  include Solr::HTTPClient::Util
  
  attr :uri
  attr :c
  
  def initialize(url)
    @uri = URI.parse(url)
    @c = Net::HTTP.new(@uri.host, @uri.port)
  end
  
  def get(path, params={})
    url = _build_url(path, params)
    net_http_response = @c.get(url)
    create_http_context(net_http_response, url, path, params)
  end
  
  def post(path, data, params={}, headers={})
    url = _build_url(path, params)
    net_http_response = @c.post(url, data, headers)
    create_http_context(net_http_response, url, path, params, data, headers)
  end
  
  protected
  
  def create_http_context(net_http_response, url, path, params, data=nil, headers={})
    full_url = "#{@uri.scheme}://#{@uri.host}"
    full_url += @uri.port ? ":#{@uri.port}" : ''
    full_url += url
    {
      :status_code=>net_http_response.code.to_i,
      :body=>net_http_response.body,
      :url=>full_url,
      :path=>path,
      :params=>params,
      :data=>data,
      :headers=>headers
    }
  end
  
  def _build_url(path, params={})
    build_url(@uri.path + path, params, @uri.query)
  end
  
end