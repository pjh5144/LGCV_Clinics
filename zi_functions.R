zeroinfl <- function(formula, data, subset, na.action, weights, offset,
                     dist = c("poisson", "negbin", "geometric", "binomial"),
                     link = c("logit", "probit", "cloglog", "cauchit", "log"),
                     size = NULL,
                     control = zeroinfl.control(...),
                     model = TRUE, y = TRUE, x = FALSE, ...)
{
  ## set up likelihood
  ziPoisson <- function(parms) {
    ## count mean
    mu <- as.vector(exp(X %*% parms[1:kx] + offsetx))
    ## binary mean
    phi <- as.vector(linkinv(Z %*% parms[(kx+1):(kx+kz)] + offsetz))    
    sum(suppressWarnings(dzipois(Y, lambda = mu, pi = phi, log = TRUE)) * weights)
  }
  
  ziNegBin <- function(parms) {
    ## count mean
    mu <- as.vector(exp(X %*% parms[1:kx] + offsetx))
    ## binary mean
    phi <- as.vector(linkinv(Z %*% parms[(kx+1):(kx+kz)] + offsetz))
    ## negbin size
    theta <- exp(parms[(kx+kz)+1])
    sum(suppressWarnings(dzinbinom(Y, mu = mu, theta = theta, pi = phi, log = TRUE)) * weights)
  }
  
  ziGeom <- function(parms) ziNegBin(c(parms, 0))
  
  ziBinom <- function(parms) {
    ## count mean
    mu <- size * as.vector(linkinv(X %*% parms[1:kx] + offsetx))
    ## binary mean
    phi <- as.vector(linkinv(Z %*% parms[(kx+1):(kx+kz)] + offsetz))
    
    ## log-likelihood for y = 0 and y >= 1
    loglik0 <- log( phi + exp( log(1-phi) + dbinom(0, prob = mu/size, size = size, log = TRUE) ) )
    loglik1 <- log(1-phi) + dbinom(Y, prob = mu/size, size = size, log = TRUE)
    
    ## collect and return
    loglik <- sum(weights[Y0] * loglik0[Y0]) + sum(weights[Y1] * loglik1[Y1])
    loglik
  }
  
  gradPoisson <- function(parms) {
    ## count mean
    eta <- as.vector(X %*% parms[1:kx] + offsetx)
    mu <- exp(eta)
    ## binary mean
    etaz <- as.vector(Z %*% parms[(kx+1):(kx+kz)] + offsetz)
    muz <- linkinv(etaz)
    
    wres <- szipois(Y, lambda = mu, pi = muz)
    colSums(weights * cbind(wres[, "lambda"] * mu * X, wres[, "pi"] * linkobj$mu.eta(etaz) * Z))
  }
  
  gradGeom <- function(parms) {
    ## count mean
    mu <- exp(as.vector(X %*% parms[1:kx] + offsetx))
    ## binary mean
    etaz <- as.vector(Z %*% parms[(kx+1):(kx+kz)] + offsetz)
    muz <- linkinv(etaz)
    
    wres <- szinbinom(Y, mu = mu, theta = 1, pi = muz, parameter = c("mu", "pi"))
    colSums(weights * cbind(wres[, "mu"] * mu * X, wres[, "pi"] * linkobj$mu.eta(etaz) * Z))
  }
  
  gradNegBin <- function(parms) {
    ## count mean
    mu <- exp(as.vector(X %*% parms[1:kx] + offsetx))
    ## binary mean
    etaz <- as.vector(Z %*% parms[(kx+1):(kx+kz)] + offsetz)
    muz <- linkinv(etaz)
    ## negbin size
    theta <- exp(parms[(kx+kz)+1])
    
    wres <- szinbinom(Y, mu = mu, theta = theta, pi = muz)
    colSums(weights * cbind(wres[, "mu"] * mu * X, wres[, "pi"] * linkobj$mu.eta(etaz) * Z, wres[, "theta"] * theta))
  }
  
  gradBinom <- function(parms) {
    ## count mean
    eta <- as.vector(X %*% parms[1:kx] + offsetx)
    mu <- size * linkinv(eta)
    ## binary mean
    etaz <- as.vector(Z %*% parms[(kx+1):(kx+kz)] + offsetz)
    muz <- linkinv(etaz)
    
    ## densities at 0
    clogdens0 <- dbinom(0, prob = mu/size, size = size, log = TRUE)
    dens0 <- muz * (1 - as.numeric(Y1)) + exp(log(1 - muz) + clogdens0)
    
    ## working residuals  
    wres_count <- ifelse(Y1, Y - mu * (Y + 1)/(mu + 1), -exp(-log(dens0) +
                                                               log(1 - muz) + clogdens0 - log(mu + 1) + log(mu)))
    wres_zero <- ifelse(Y1, -1/(1-muz) * linkobj$mu.eta(etaz),
                        (linkobj$mu.eta(etaz) - exp(clogdens0) * linkobj$mu.eta(etaz))/dens0)
    
    colSums(cbind(wres_count * weights * X, wres_zero * weights * Z))
  }
  
  dist <- match.arg(dist)
  loglikfun <- switch(dist,
                      "poisson" = ziPoisson,
                      "geometric" = ziGeom,
                      "negbin" = ziNegBin,
                      "binomial" = ziBinom)
  gradfun <- switch(dist,
                    "poisson" = gradPoisson,
                    "geometric" = gradGeom,
                    "negbin" = gradNegBin,
                    "binomial" = gradBinom)
  
  ## binary link processing
  linkstr <- match.arg(link)
  linkobj <- make.link(linkstr)
  linkinv <- linkobj$linkinv
  
  if(control$trace) cat("Zero-inflated Count Model\n",
                        paste("count model:", dist, "with",  if(dist == "binomial") linkstr else "log", "link\n"),
                        paste("zero-inflation model: binomial with", linkstr, "link\n"), sep = "")
  
  
  ## call and formula
  cl <- match.call()
  if(missing(data)) data <- environment(formula)
  mf <- match.call(expand.dots = FALSE)
  m <- match(c("formula", "data", "subset", "na.action", "weights", "offset"), names(mf), 0)
  mf <- mf[c(1, m)]
  mf$drop.unused.levels <- TRUE
  
  ## extended formula processing
  if(length(formula[[3]]) > 1 && identical(formula[[3]][[1]], as.name("|")))
  {
    ff <- formula
    formula[[3]][1] <- call("+")
    mf$formula <- formula
    ffc <- . ~ .
    ffz <- ~ .
    ffc[[2]] <- ff[[2]]
    ffc[[3]] <- ff[[3]][[2]]
    ffz[[3]] <- ff[[3]][[3]]
    ffz[[2]] <- NULL
  } else {
    ffz <- ffc <- ff <- formula
    ffz[[2]] <- NULL
  }
  if(inherits(try(terms(ffz), silent = TRUE), "try-error")) {
    ffz <- eval(parse(text = sprintf( paste("%s -", deparse(ffc[[2]])), deparse(ffz) )))
  }
  
  ## call model.frame()
  mf[[1]] <- as.name("model.frame")
  mf <- eval(mf, parent.frame())
  
  ## extract terms, model matrices, response
  mt <- attr(mf, "terms")
  mtX <- terms(ffc, data = data)
  X <- model.matrix(mtX, mf)
  mtZ <- terms(ffz, data = data)
  mtZ <- terms(update(mtZ, ~ .), data = data)
  Z <- model.matrix(mtZ, mf)
  Y <- model.response(mf, "numeric")
  
  ## sanity checks
  if(length(Y) < 1) stop("empty model")
  if(all(Y > 0)) stop("invalid dependent variable, minimum count is not zero")  
  if(!isTRUE(all.equal(as.vector(Y), as.integer(round(Y + 0.001)))))
    stop("invalid dependent variable, non-integer values")
  Y <- as.integer(round(Y + 0.001))
  if(any(Y < 0)) stop("invalid dependent variable, negative counts")
  
  ## size of binomial experiments
  if(dist == "binomial") {
    if(is.null(size)) size <- max(Y)
    stopifnot(all(Y <= size))
  }
  
  if(control$trace) {
    cat("dependent variable:\n")
    tab <- table(factor(Y, levels = 0:max(Y)), exclude = NULL)
    names(dimnames(tab)) <- NULL
    print(tab)
  }
  
  ## convenience variables
  n <- length(Y)
  kx <- NCOL(X)
  kz <- NCOL(Z)
  Y0 <- Y <= 0
  Y1 <- Y > 0
  
  ## weights and offset
  weights <- model.weights(mf)
  if(is.null(weights)) weights <- 1
  if(length(weights) == 1) weights <- rep.int(weights, n)
  weights <- as.vector(weights)
  names(weights) <- rownames(mf)
  
  offsetx <- model_offset_2(mf, terms = mtX, offset = TRUE)
  if(is.null(offsetx)) offsetx <- 0
  if(length(offsetx) == 1) offsetx <- rep.int(offsetx, n)
  offsetx <- as.vector(offsetx)
  offsetz <- model_offset_2(mf, terms = mtZ, offset = FALSE)
  if(is.null(offsetz)) offsetz <- 0
  if(length(offsetz) == 1) offsetz <- rep.int(offsetz, n)
  offsetz <- as.vector(offsetz)
  
  ## starting values
  start <- control$start
  if(!is.null(start)) {
    valid <- TRUE
    if(!("count" %in% names(start))) {
      valid <- FALSE
      warning("invalid starting values, count model coefficients not specified")
      start$count <- rep.int(0, kx)
    }
    if(!("zero" %in% names(start))) {
      valid <- FALSE
      warning("invalid starting values, zero-inflation model coefficients not specified")
      start$zero <- rep.int(0, kz)
    }
    if(length(start$count) != kx) {
      valid <- FALSE
      warning("invalid starting values, wrong number of count model coefficients")
    }
    if(length(start$zero) != kz) {
      valid <- FALSE
      warning("invalid starting values, wrong number of zero-inflation model coefficients")
    }
    if(dist == "negbin") {
      if(!("theta" %in% names(start))) start$theta <- 1
      start <- list(count = start$count, zero = start$zero, theta = as.vector(start$theta[1]))
    } else {
      start <- list(count = start$count, zero = start$zero)
    }
    if(!valid) start <- NULL
  }
  
  if(is.null(start)) {
    if(control$trace) cat("generating starting values...")
    model_count <- if(dist == "binomial") {
      glm.fit(X, cbind(Y, size - Y), family = binomial(link = linkstr), weights = weights, offset = offsetx)
    } else {
      glm.fit(X, Y, family = poisson(), weights = weights, offset = offsetx)
    }
    model_zero <- glm.fit(Z, as.integer(Y0), weights = weights, family = binomial(link = linkstr), offset = offsetz)
    start <- list(count = model_count$coefficients, zero = model_zero$coefficients)
    if(dist == "negbin") start$theta <- 1
    
    ## EM estimation of starting values
    if(control$EM & dist == "poisson") {
      mui <- model_count$fitted
      probi <- model_zero$fitted
      probi <- probi/(probi + (1-probi) * dpois(0, mui))
      probi[Y1] <- 0
      
      ll_new <- loglikfun(c(start$count, start$zero))
      ll_old <- 2 * ll_new
      
      while(abs((ll_old - ll_new)/ll_old) > control$reltol) {
        ll_old <- ll_new
        model_count <- glm.fit(X, Y, weights = weights * (1-probi), offset = offsetx,
                               family = poisson(), start = start$count)
        model_zero <- suppressWarnings(glm.fit(Z, probi, weights = weights, offset = offsetz,
                                               family = binomial(link = linkstr), start = start$zero))
        mui <- model_count$fitted
        probi <- model_zero$fitted
        probi <- probi/(probi + (1-probi) * dpois(0, mui))
        probi[Y1] <- 0
        start <- list(count = model_count$coefficients, zero = model_zero$coefficients)
        ll_new <- loglikfun(c(start$count, start$zero))
      }
    }
    
    if(control$EM & dist == "geometric") {
      mui <- model_count$fitted
      probi <- model_zero$fitted
      probi <- probi/(probi + (1-probi) * dnbinom(0, size = 1, mu = mui))
      probi[Y1] <- 0
      
      ll_new <- loglikfun(c(start$count, start$zero))
      ll_old <- 2 * ll_new      
      
      while(abs((ll_old - ll_new)/ll_old) > control$reltol) {
        ll_old <- ll_new
        model_count <- suppressWarnings(glm.fit(X, Y, weights = weights * (1-probi),
                                                offset = offsetx, family = negative.binomial(1), start = start$count))
        model_zero <- suppressWarnings(glm.fit(Z, probi, weights = weights,
                                               offset = offsetz, family = binomial(link = linkstr), start = start$zero))
        start <- list(count = model_count$coefficients, zero = model_zero$coefficients)
        mui <- model_count$fitted
        probi <- model_zero$fitted
        probi <- probi/(probi + (1-probi) * dnbinom(0, size = 1, mu = mui))
        probi[Y1] <- 0
        ll_new <- loglikfun(c(start$count, start$zero))
      }
    }
    
    if(control$EM & dist == "negbin") {
      mui <- model_count$fitted
      probi <- model_zero$fitted
      probi <- probi/(probi + (1-probi) * dnbinom(0, size = start$theta, mu = mui))
      probi[Y1] <- 0
      
      ll_new <- loglikfun(c(start$count, start$zero, log(start$theta)))      
      ll_old <- 2 * ll_new      
      
      ## offset handling in glm.nb is sub-optimal, hence...
      offset <- offsetx
      
      while(abs((ll_old - ll_new)/ll_old) > control$reltol) {
        ll_old <- ll_new
        model_count <- suppressWarnings(glm.nb(Y ~ 0 + X + offset(offset), weights = weights * (1-probi),
                                               start = start$count, init.theta = start$theta))
        model_zero <- suppressWarnings(glm.fit(Z, probi, weights = weights, offset = offsetz,
                                               family = binomial(link = linkstr), start = start$zero))
        start <- list(count = model_count$coefficients, zero = model_zero$coefficients, theta = model_count$theta)
        mui <- model_count$fitted
        probi <- model_zero$fitted
        probi <- probi/(probi + (1-probi) * dnbinom(0, size = start$theta, mu = mui))
        probi[Y1] <- 0
        ll_new <- loglikfun(c(start$count, start$zero, log(start$theta)))
      }
    }
    
    if(control$EM & dist == "binomial") {
      mui <- model_count$fitted
      probi <- model_zero$fitted
      probi <- probi/(probi + (1-probi) * dbinom(0, prob = mui, size = size))
      probi[Y1] <- 0
      
      ll_new <- loglikfun(c(start$count, start$zero))
      ll_old <- 2 * ll_new
      
      while(abs((ll_old - ll_new)/ll_old) > control$reltol) {
        ll_old <- ll_new
        model_count <- glm.fit(X, cbind(Y, size - Y), weights = weights * (1-probi), offset = offsetx,
                               family = binomial(link = linkstr), start = start$count)
        model_zero <- suppressWarnings(glm.fit(Z, probi, weights = weights, offset = offsetz,
                                               family = binomial(link = linkstr), start = start$zero))
        mui <- model_count$fitted
        probi <- model_zero$fitted
        probi <- probi/(probi + (1-probi) * dbinom(0, prob = mui, size = size))
        probi[Y1] <- 0
        start <- list(count = model_count$coefficients, zero = model_zero$coefficients)
        ll_new <- loglikfun(c(start$count, start$zero))
      }
    }
    
    if(control$trace) cat("done\n")
  }
  
  
  ## ML estimation
  if(control$trace) cat("calling optim() for ML estimation:\n")
  method <- control$method
  hessian <- control$hessian
  ocontrol <- control
  control$method <- control$hessian <- control$EM <- control$start <- NULL
  fit <- optim(fn = loglikfun, gr = gradfun,
               par = c(start$count, start$zero, if(dist == "negbin") log(start$theta) else NULL),
               method = method, hessian = hessian, control = control)
  if(fit$convergence > 0) warning("optimization failed to converge")
  
  ## coefficients and covariances
  coefc <- fit$par[1:kx]
  names(coefc) <- names(start$count) <- colnames(X)
  coefz <- fit$par[(kx+1):(kx+kz)]
  names(coefz) <- names(start$zero) <- colnames(Z)
  
  np <- kx + kz + (dist == "negbin")
  vc <- if(hessian) {
    tryCatch(-solve(as.matrix(fit$hessian)),
             error = function(e) {
               warning(e$message, call = FALSE)
               matrix(NA_real_, nrow = np, ncol = np)
             })
  } else {
    matrix(NA_real_, nrow = np, ncol = np)
  }
  if(dist == "negbin") {
    theta <- as.vector(exp(fit$par[np]))
    SE.logtheta <- as.vector(sqrt(diag(vc)[np]))
    vc <- vc[-np, -np, drop = FALSE]
  } else {
    theta <- NULL
    SE.logtheta <- NULL
  }
  colnames(vc) <- rownames(vc) <- c(paste("count", colnames(X), sep = "_"),
                                    paste("zero",  colnames(Z), sep = "_"))
  
  ## fitted and residuals
  mu <- drop(X %*% coefc + offsetx)
  mu <- if(dist == "binomial") size * linkinv(mu) else exp(mu)
  phi <- linkinv(drop(Z %*% coefz + offsetz))
  Yhat <- (1-phi) * mu
  res <- sqrt(weights) * (Y - Yhat)
  
  ## effective observations
  nobs <- sum(weights > 0) ## = n - sum(weights == 0)
  
  rval <- list(coefficients = list(count = coefc, zero = coefz),
               residuals = res,
               fitted.values = Yhat,
               optim = fit,
               method = method,
               control = ocontrol,
               start = start,
               weights = if(identical(as.vector(weights), rep.int(1L, n))) NULL else weights,
               offset = list(count = if(identical(offsetx, rep.int(0, n))) NULL else offsetx,
                             zero = if(identical(offsetz, rep.int(0, n))) NULL else offsetz),
               n = nobs,
               df.null = nobs - 2,
               df.residual = nobs - (kx + kz + (dist == "negbin")),
               terms = list(count = mtX, zero = mtZ, full = mt),
               theta = theta,
               SE.logtheta = SE.logtheta,
               loglik = fit$value,
               vcov = vc,
               dist = dist,
               link = linkstr,
               linkinv = linkinv,
               converged = fit$convergence < 1,
               call = cl,
               formula = ff,
               levels = .getXlevels(mt, mf),
               contrasts = list(count = attr(X, "contrasts"), zero = attr(Z, "contrasts")),
               size = if(dist == "binomial") size else NULL
  )
  if(model) rval$model <- mf
  if(y) rval$y <- Y
  if(x) rval$x <- list(count = X, zero = Z)
  
  class(rval) <- "zeroinfl"
  return(rval)
}

zeroinfl.control <- function(method = "BFGS", maxit = 10000, trace = FALSE,
                             EM = FALSE, start = NULL, hessian = TRUE, ...)
{
  rval <- list(method = method, maxit = maxit, trace = trace, EM = EM, start = start, hessian = hessian)
  rval <- c(rval, list(...))
  if(!is.null(rval$fnscale)) warning("fnscale must not be modified")
  rval$fnscale <- -1
  if(is.null(rval$reltol)) rval$reltol <- .Machine$double.eps^(1/1.6)
  rval
}

coef.zeroinfl <- function(object, model = c("full", "count", "zero"), ...) {
  model <- match.arg(model)
  rval <- object$coefficients
  rval <- switch(model,
                 "full" = structure(c(rval$count, rval$zero),
                                    .Names = c(paste("count", names(rval$count), sep = "_"),
                                               paste("zero", names(rval$zero), sep = "_"))),
                 "count" = rval$count,
                 "zero" = rval$zero)
  rval
}

vcov.zeroinfl <- function(object, model = c("full", "count", "zero"), ...) {
  model <- match.arg(model)
  rval <- object$vcov
  if(model == "full") return(rval)
  
  cf <- object$coefficients[[model]]
  wi <- seq_along(object$coefficients$count)
  rval <- if(model == "count") rval[wi, wi, drop = FALSE] else rval[-wi, -wi, drop = FALSE]
  colnames(rval) <- rownames(rval) <- names(cf)
  return(rval)
}

logLik.zeroinfl <- function(object, ...) {
  structure(object$loglik, df = object$n - object$df.residual, nobs = object$n, class = "logLik")
}

nobs.zeroinfl <- function(object, ...) object$n

print.zeroinfl <- function(x, digits = max(3, getOption("digits") - 3), ...)
{
  
  cat("\nCall:", deparse(x$call, width.cutoff = floor(getOption("width") * 0.85)), "", sep = "\n")
  
  if(!x$converged) {
    cat("model did not converge\n")
  } else {
    cat(paste("Count model coefficients (", x$dist, " with ", if(x$dist == "binomial") x$link else "log", " link):\n", sep = ""))
    print.default(format(x$coefficients$count, digits = digits), print.gap = 2, quote = FALSE)
    if(x$dist == "negbin") cat(paste("Theta =", round(x$theta, digits), "\n"))
    
    cat(paste("\nZero-inflation model coefficients (binomial with ", x$link, " link):\n", sep = ""))
    print.default(format(x$coefficients$zero, digits = digits), print.gap = 2, quote = FALSE)
    cat("\n")
  }
  
  invisible(x)
}

summary.zeroinfl <- function(object,...)
{
  ## residuals
  object$residuals <- residuals(object, type = "pearson")
  
  ## compute z statistics
  kc <- length(object$coefficients$count)
  kz <- length(object$coefficients$zero)
  se <- sqrt(diag(object$vcov))
  coef <- c(object$coefficients$count, object$coefficients$zero)  
  if(object$dist == "negbin") {
    coef <- c(coef[1:kc], "Log(theta)" = log(object$theta), coef[(kc+1):(kc+kz)])
    se <- c(se[1:kc], object$SE.logtheta, se[(kc+1):(kc+kz)])
    kc <- kc+1
  }
  zstat <- coef/se
  pval <- 2*pnorm(-abs(zstat))
  coef <- cbind(coef, se, zstat, pval)
  colnames(coef) <- c("Estimate", "Std. Error", "z value", "Pr(>|z|)")
  object$coefficients$count <- coef[1:kc,,drop = FALSE]
  object$coefficients$zero <- coef[(kc+1):(kc+kz),,drop = FALSE]
  
  ## delete some slots
  object$fitted.values <- object$terms <- object$model <- object$y <-
    object$x <- object$levels <- object$contrasts <- object$start <- NULL
  
  ## return
  class(object) <- "summary.zeroinfl"
  object
}

print.summary.zeroinfl <- function(x, digits = max(3, getOption("digits") - 3), ...)
{
  
  cat("\nCall:", deparse(x$call, width.cutoff = floor(getOption("width") * 0.85)), "", sep = "\n")
  
  if(!x$converged) {
    cat("model did not converge\n")
  } else {
    
    cat("Pearson residuals:\n")
    print(structure(quantile(x$residuals),
                    names = c("Min", "1Q", "Median", "3Q", "Max")), digits = digits, ...)  
    
    cat(paste("\nCount model coefficients (", x$dist, " with ", if(x$dist == "binomial") x$link else "log", " link):\n", sep = ""))
    printCoefmat(x$coefficients$count, digits = digits, signif.legend = FALSE)
    
    cat(paste("\nZero-inflation model coefficients (binomial with ", x$link, " link):\n", sep = ""))
    printCoefmat(x$coefficients$zero, digits = digits, signif.legend = FALSE)
    
    if(getOption("show.signif.stars") & isTRUE(any(rbind(x$coefficients$count, x$coefficients$zero)[,4] < 0.1)))
      cat("---\nSignif. codes: ", "0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1", "\n")
    
    if(x$dist == "negbin") cat(paste("\nTheta =", round(x$theta, digits), "\n")) else cat("\n")
    cat(paste("Number of iterations in", x$method, "optimization:", tail(na.omit(x$optim$count), 1), "\n"))
    cat("Log-likelihood:", formatC(x$loglik, digits = digits), "on", x$n - x$df.residual, "Df\n")
  }
  
  invisible(x)
}

predict.zeroinfl <- function(object, newdata, type = c("response", "prob", "count", "zero"),
                             na.action = na.pass, at = NULL, ...)
{
  type <- match.arg(type)
  
  ## if no new data supplied
  if(missing(newdata)) {
    rval <- object$fitted.values
    if(type != "response") {
      if(!is.null(object$x)) {
        X <- object$x$count
        Z <- object$x$zero
      } else if(!is.null(object$model)) {
        X <- model.matrix(object$terms$count, object$model, contrasts = object$contrasts$count)
        Z <- model.matrix(object$terms$zero,  object$model, contrasts = object$contrasts$zero)	
      } else {
        stop("predicted probabilities cannot be computed with missing newdata")
      }
      offsetx <- if(is.null(object$offset$count)) rep.int(0, NROW(X)) else object$offset$count
      offsetz <- if(is.null(object$offset$zero))  rep.int(0, NROW(Z)) else object$offset$zero
      mu <- drop(X %*% object$coefficients$count + offsetx)
      mu <- if(object$dist == "binomial") object$size * object$linkinv(mu) else exp(mu)
      phi <- object$linkinv(drop(Z %*% object$coefficients$zero + offsetz))
    }
  } else {
    mf <- model.frame(delete.response(object$terms$full), newdata, na.action = na.action, xlev = object$levels)
    X <- model.matrix(delete.response(object$terms$count), mf, contrasts = object$contrasts$count)
    Z <- model.matrix(delete.response(object$terms$zero),  mf, contrasts = object$contrasts$zero)
    offsetx <- model_offset_2(mf, terms = object$terms$count, offset = FALSE)
    offsetz <- model_offset_2(mf, terms = object$terms$zero,  offset = FALSE)
    if(is.null(offsetx)) offsetx <- rep.int(0, NROW(X))
    if(is.null(offsetz)) offsetz <- rep.int(0, NROW(Z))
    if(!is.null(object$call$offset)) offsetx <- offsetx + eval(object$call$offset, newdata)
    
    mu <- drop(X %*% object$coefficients$count + offsetx)
    mu <- if(object$dist == "binomial") object$size * object$linkinv(mu) else exp(mu)
    phi <- object$linkinv(drop(Z %*% object$coefficients$zero + offsetz))
    rval <- (1-phi) * mu
  }
  
  ## predicted means for count/zero component
  if(type == "count") rval <- mu
  if(type == "zero") rval <- phi
  
  ## predicted probabilities
  if(type == "prob") {
    if(!is.null(object$y)) y <- object$y
    else if(!is.null(object$model)) y <- model.response(object$model)
    else stop("predicted probabilities cannot be computed for fits with y = FALSE and model = FALSE")
    
    yUnique <- if(is.null(at)) 0:max(y) else at
    nUnique <- length(yUnique)
    rval <- matrix(NA, nrow = length(rval), ncol = nUnique)
    dimnames(rval) <- list(rownames(X), yUnique)
    
    switch(object$dist,
           "poisson" = {
             for(i in 1:nUnique) rval[,i] <- if(yUnique[i] == 0) phi + (1-phi) * exp(-mu) else
               (1-phi) * dpois(yUnique[i], lambda = mu)
           },
           "negbin" = {
             theta <- object$theta
             for(i in 1:nUnique) rval[,i] <- if(yUnique[i] == 0) phi + (1-phi) * dnbinom(0, mu = mu, size = theta) else
               (1-phi) * dnbinom(yUnique[i], mu = mu, size = theta)
           },
           "geometric" = {
             for(i in 1:nUnique) rval[,i] <- if(yUnique[i] == 0) phi + (1-phi) * dnbinom(0, mu = mu, size = 1) else
               (1-phi) * dnbinom(yUnique[i], mu = mu, size = 1)
           })
  }
  
  return(rval)
}

fitted.zeroinfl <- function(object, ...) {
  object$fitted.values
}

residuals.zeroinfl <- function(object, type = c("pearson", "response"), ...) {
  
  type <- match.arg(type)
  res <- object$residuals
  
  switch(type,
         
         "response" = {
           return(res)
         },
         
         "pearson" = {
           mu <- predict(object, type = "count")
           phi <- predict(object, type = "zero")
           theta1 <- switch(object$dist,
                            "poisson" = 0,
                            "geometric" = 1,
                            "negbin" = 1/object$theta,
                            "binomial" = 0) ## FIXME
           vv <- object$fitted.values * (1 + (phi + theta1) * mu)
           return(res/sqrt(vv))  
         })
}

terms.zeroinfl <- function(x, model = c("count", "zero"), ...) {
  x$terms[[match.arg(model)]]
}

model.matrix.zeroinfl <- function(object, model = c("count", "zero"), ...) {
  model <- match.arg(model)
  if(!is.null(object$x)) rval <- object$x[[model]]
  else if(!is.null(object$model)) rval <- model.matrix(object$terms[[model]], object$model, contrasts = object$contrasts[[model]])
  else stop("not enough information in fitted model to return model.matrix")
  return(rval)
}

predprob.zeroinfl <- function(obj, ...) {
  predict(obj, type = "prob", ...)
}

extractAIC.zeroinfl <- function(fit, scale = NULL, k = 2, ...) {
  c(attr(logLik(fit), "df"), AIC(fit, k = k))
}
