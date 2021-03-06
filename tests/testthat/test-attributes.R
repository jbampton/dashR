context("attributes")

test_that("stylesheets can be added with or without attributes", {
  library(dashHtmlComponents)
  stylesheet_pattern <- '^.*<link href="(https.*)">.*$'
  script_pattern <- '^.*<script src="(https.*)">.*$'
      
  app <- Dash$new(external_stylesheets = list(
                                           list(
                                             href="https://codepen.io/chriddyp/pen/bWLwgP.css",
                                             hreflang="en-us")
                                           ),
                  external_scripts = list(
                    src="https://www.google-analytics.com/analytics.js",
                    list(
                      src = "https://cdn.polyfill.io/v2/polyfill.min.js"
                    ),
                    list(
                      src = "https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.10/lodash.core.js",
                      integrity = "sha256-Qqd/EfdABZUcAxjOkMi8eGEivtdTkh3b65xCZL4qAQA=",
                      crossorigin = "anonymous"
                    )
                  )
          )
  
  app$layout(htmlDiv(
    "Hello world!"
  )
  )
  
  request_with_attributes <- fiery::fake_request(
    "http://127.0.0.1:8050"
  )
  
  # start up Dash briefly to generate the index
  app$run_server(block=FALSE)
  app$server$stop()
  
  response_with_attributes <- app$server$test_request(request_with_attributes)

  tags_by_line <- lapply(strsplit(response_with_attributes$body, "\n "), function(x) trimws(x))[[1]]
  stylesheet_hrefs <- grep(stylesheet_pattern, tags_by_line, value = TRUE)
  script_hrefs <- grep(script_pattern, tags_by_line, value = TRUE)
    
  expect_equal(
    stylesheet_hrefs,
    "<link href=\"https://codepen.io/chriddyp/pen/bWLwgP.css\" hreflang=\"en-us\" rel=\"stylesheet\">"
  )
  
  expect_equal(
    script_hrefs,
    c("<script src=\"https://www.google-analytics.com/analytics.js\"></script>", 
      "<script src=\"https://cdn.polyfill.io/v2/polyfill.min.js\"></script>", 
      "<script src=\"https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.10/lodash.core.js\" integrity=\"sha256-Qqd/EfdABZUcAxjOkMi8eGEivtdTkh3b65xCZL4qAQA=\" crossorigin=\"anonymous\"></script>"
    )
  )

  app <- Dash$new(serve_locally=FALSE, external_stylesheets = list(
                                           list(
                                             href="https://codepen.io/chriddyp/pen/bWLwgP.css",
                                             hreflang="en-us")
                                           ),
                  external_scripts = list(
                    src="https://www.google-analytics.com/analytics.js",
                    list(
                      src = "https://cdn.polyfill.io/v2/polyfill.min.js"
                    ),
                    list(
                      src = "https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.10/lodash.core.js",
                      integrity = "sha256-Qqd/EfdABZUcAxjOkMi8eGEivtdTkh3b65xCZL4qAQA=",
                      crossorigin = "anonymous"
                    )
                  )
          )
  
  app$layout(htmlDiv(
    "Hello world!"
  )
  )
  
  request_with_attributes <- fiery::fake_request(
    "http://127.0.0.1:8050"
  )
  
  # start up Dash briefly to generate the index
  app$run_server(block=FALSE)
  app$server$stop()
  
  response_with_attributes <- app$server$test_request(request_with_attributes)

  tags_by_line <- lapply(strsplit(response_with_attributes$body, "\n "), function(x) trimws(x))[[1]]
  stylesheet_hrefs <- grep(stylesheet_pattern, tags_by_line, value = TRUE)
  script_hrefs <- grep(script_pattern, tags_by_line, value = TRUE)

  # construct the script tags as they should be generated within
  # Dash for R this way the mod times and version numbers will
  # always be in sync with those used by the backend
  internal_hrefs <- vapply(dash:::.dash_js_metadata(), function(x) x$src$href, character(1))
  dhc <- dashHtmlComponents:::.dashHtmlComponents_js_metadata()[[1]]
  dhc_path <- dash:::getDependencyPath(dhc)
  modtime <- as.integer(file.mtime(dhc_path))
  filename <- basename(dash:::buildFingerprint(dhc$script, dhc$version, modtime))
  dhc_ref <- paste0("/",
                    "_dash-component-suites/",
                    dhc$name,
                    "/",
                    filename,
                    "?v=",
                    dhc$version,
                    "&m=",
                    modtime)

  all_tags <- glue::glue("<script src=\"{c(internal_hrefs[c(\"react-prod\", 
                                                            \"react-dom-prod\",
                                                            \"prop-types-prod\",
                                                            \"polyfill-prod\")],
                                           dhc_ref,
                                           internal_hrefs[\"dash-renderer-prod\"])}\"></script>\n")

  expect_equal(
    stylesheet_hrefs,
    "<link href=\"https://codepen.io/chriddyp/pen/bWLwgP.css\" hreflang=\"en-us\" rel=\"stylesheet\">"
  )

  expect_equal(
    script_hrefs,
      c(glue::glue_collapse(all_tags, sep="\n"),
      "<script src=\"https://www.google-analytics.com/analytics.js\"></script>", 
      "<script src=\"https://cdn.polyfill.io/v2/polyfill.min.js\"></script>", 
      "<script src=\"https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.10/lodash.core.js\" integrity=\"sha256-Qqd/EfdABZUcAxjOkMi8eGEivtdTkh3b65xCZL4qAQA=\" crossorigin=\"anonymous\"></script>"
    )
  )

})

test_that("invalid attributes trigger an error", {
  library(dashHtmlComponents)

  external_stylesheets <- list(
                            list(
                              href="https://codepen.io/chriddyp/pen/bWLwgP.css",
                              foo="somedata",
                              bar="moredata"
                              )
                            )

  external_scripts <- list(
                        "https://www.google-analytics.com/analytics.js",
                        list(
                          src = "https://cdn.polyfill.io/v2/polyfill.min.js"
                        ),
                        list(
                          src = "https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.10/lodash.core.js",
                          integrity = "sha256-Qqd/EfdABZUcAxjOkMi8eGEivtdTkh3b65xCZL4qAQA=",
                          baz = "anonymous"
                        )
                      )

  expect_error(dash:::assertValidExternals(external_scripts, external_stylesheets), 
    "The following script or stylesheet attributes are invalid: baz, foo, bar.")
})

test_that("not passing named attributes triggers an error", {
  library(dashHtmlComponents)

  external_stylesheets <- list(
                            list(
                              href="https://codepen.io/chriddyp/pen/bWLwgP.css",
                              foo="somedata",
                              "moredata"
                              )
                            )
                                            
  external_scripts <- list()

  expect_error(dash:::assertValidExternals(external_scripts, external_stylesheets), 
    "Please verify that all attributes are named elements when specifying URLs for scripts and stylesheets.")
})

test_that("stylesheet can be passed as a simple list", {
  library(dashHtmlComponents)
  stylesheet_pattern <- '^.*<link href="(https.*)">.*$'
  script_pattern <- '^.*<script src="(https.*)">.*$'

  app <- Dash$new(external_stylesheets = list("https://codepen.io/chriddyp/pen/bWLwgP.css"))

  app$layout(htmlDiv(
    "Hello world!"
  )
  )

  request_with_attributes <- fiery::fake_request(
    "http://127.0.0.1:8050"
  )

  # start up Dash briefly to generate the index
  app$run_server(block=FALSE)
  app$server$stop()

  response_with_attributes <- app$server$test_request(request_with_attributes)

  tags_by_line <- lapply(strsplit(response_with_attributes$body, "\n "), function(x) trimws(x))[[1]]
  stylesheet_hrefs <- grep(stylesheet_pattern, tags_by_line, value = TRUE)

  expect_equal(
    stylesheet_hrefs,
    "<link href=\"https://codepen.io/chriddyp/pen/bWLwgP.css\" rel=\"stylesheet\">"
  )
})

test_that("not passing named attributes triggers an error", {
  library(dashHtmlComponents)

  external_stylesheets = list(
                            list(
                              href="https://codepen.io/chriddyp/pen/bWLwgP.css",
                              "somedata"
                              )
                            )

  expect_error(app <- Dash$new(external_stylesheets=external_stylesheets),
    "Please verify that all attributes are named elements when specifying URLs for scripts and stylesheets.")
  expect_error(app <- Dash$new(serve_locally=FALSE, external_stylesheets=external_stylesheets),
    "Please verify that all attributes are named elements when specifying URLs for scripts and stylesheets.")
})

test_that("passing a list with no href/src fails", {
  library(dashHtmlComponents)
  stylesheet_pattern <- '^.*<link href="(https.*)">.*$'
  script_pattern <- '^.*<script src="(https.*)">.*$'
      
  expect_error(app <- Dash$new(external_stylesheets = list(
                      href="https://codepen.io/chriddyp/pen/bWLwgP.css",
                            list(
                              integrity="somedata",
                              crossorigin="moredata"
                              )
                            )
                  ),
                  "A valid URL must be included with every entry in external_stylesheets. Please sure no 'href' entries are missing or malformed.")

  expect_error(app <- Dash$new(serve_locally=FALSE, external_stylesheets = list(
                      href="https://codepen.io/chriddyp/pen/bWLwgP.css",
                            list(
                              integrity="somedata",
                              crossorigin="moredata"
                              )
                            )
                  ),
                  "A valid URL must be included with every entry in external_stylesheets. Please sure no 'href' entries are missing or malformed.")

  expect_error(app <- Dash$new(external_scripts = list(
                      href="https://rivetscriptemporium.com/test.js",
                            list(
                              integrity="somedata",
                              crossorigin="moredata"
                              )
                            )
                  ),
                  "A valid URL must be included with every entry in external_scripts. Please sure no 'src' entries are missing or malformed.")

  expect_error(app <- Dash$new(serve_locally=FALSE, external_scripts = list(
                      href="https://rivetscriptemporium.com/test.js",
                            list(
                              integrity="somedata",
                              crossorigin="moredata"
                              )
                            )
                  ),
                  "A valid URL must be included with every entry in external_scripts. Please sure no 'src' entries are missing or malformed.")
})
