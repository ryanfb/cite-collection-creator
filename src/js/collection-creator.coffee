FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v1'

google_client_id = '891199912324.apps.googleusercontent.com'

google_oauth_parameters_for_fusion_tables =
  response_type: 'token'
  redirect_uri: window.location.href.replace("#{location.hash}",'')
  scope: 'https://www.googleapis.com/auth/fusiontables https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email'
  approval_prompt: 'auto'

google_oauth_url = ->
  "https://accounts.google.com/o/oauth2/auth?#{$.param(google_oauth_parameters_for_fusion_tables)}"

build_collection_creator = ->
  create_creator_form()
  unless window.File && window.FileReader && window.FileList && window.Blob
    $('.container > h1').after $('<div>').attr('class','alert alert-error').attr('id','html5_files_error').append('Your browser does not support the HTML5 file access APIs')
    disable_creator_form()
  unless get_cookie 'access_token'
    $('.container > h1').after $('<div>').attr('class','alert alert-warning').attr('id','oauth_access_warning').append('You have not authorized this application to access your Google Fusion Tables. ')
    $('#oauth_access_warning').append $('<a>').attr('href',google_oauth_url()).append('Click here to authorize.')
    disable_creator_form()

create_creator_form = ->
  $('.container > h1').after $('<div>').attr('id','creator_form')
  $('#creator_form').append $('<p>').append('Select a collections capabilities file below.')
  $('#creator_form').append $('<input>').attr('type','file').attr('id','file_input').attr('name','file')
  $('#file_input').change (event) ->
    console.log event.target.files[0].name

disable_creator_form = ->
  $('#file_input').prop('disabled',true)

# parse URL hash parameters into an associative array object
parse_query_string = (query_string) ->
  query_string ?= location.hash.substring(1)
  params = {}
  if query_string.length > 0
    regex = /([^&=]+)=([^&]*)/g
    while m = regex.exec(query_string)
      params[decodeURIComponent(m[1])] = decodeURIComponent(m[2])
  return params

# filter URL parameters out of the window URL using replaceState 
# returns the original parameters
filter_url_params = (params, filtered_params) ->
  rewritten_params = []
  filtered_params ?= ['access_token','expires_in','token_type']
  for key, value of params
    unless _.include(filtered_params,key)
      rewritten_params.push "#{key}=#{value}"
  if rewritten_params.length > 0
    hash_string = "##{rewritten_params.join('&')}"
  else
    hash_string = ''
  history.replaceState(null,'',window.location.href.replace("#{location.hash}",hash_string))
  return params

set_cookie = (key, value, expires_in) ->
  cookie_expires = new Date
  cookie_expires.setTime(cookie_expires.getTime() + expires_in * 1000)
  cookie = "#{key}=#{value}; "
  cookie += "expires=#{cookie_expires.toGMTString()}; "
  cookie += "path=#{window.location.pathname.substring(0,window.location.pathname.lastIndexOf('/')+1)}"
  document.cookie = cookie

delete_cookie = (key) ->
  set_cookie key, null, -1

get_cookie = (key) ->
  key += "="
  for cookie_fragment in document.cookie.split(';')
    cookie_fragment = cookie_fragment.replace(/^\s+/, '')
    return cookie_fragment.substring(key.length, cookie_fragment.length) if cookie_fragment.indexOf(key) == 0
  return null

# write a Google OAuth access token into a cached cookie that should expire when the access token does
set_access_token_cookie = (params, callback) ->
  if params['access_token']?
    # validate the token per https://developers.google.com/accounts/docs/OAuth2UserAgent#validatetoken
    $.ajax "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=#{params['access_token']}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "Access Token Validation Error: #{textStatus}"
      success: (data) ->
        set_cookie('access_token',params['access_token'],params['expires_in'])
        $('#collection_select').change()
      complete: (jqXHR, textStatus) ->
        callback() if callback?

# main collection creator entry point
$(document).ready ->
  unless $('#qunit').length
    google_oauth_parameters_for_fusion_tables['client_id'] = if window.google_client_id? then window.google_client_id else google_client_id

    set_access_token_cookie filter_url_params(parse_query_string())
 
    build_collection_creator()
