json.success "true"
json.status @status || :no_content
json.message @message || "No content"
json.data { }
