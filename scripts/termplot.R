termplot= function (model, data = NULL, envir = environment(formula(model)), 
          partial.resid = FALSE, rug = FALSE, terms = NULL, se = FALSE,
          xlabs = NULL, ylabs = NULL, main = NULL, col.term = 2, lwd.term = 1.5, 
          col.se = "orange", lty.se = 2, lwd.se = 1, col.res = "gray", 
          cex = 1, pch = par("pch"), col.smth = "darkred", lty.smth = 2, 
          span.smth = 2/3, ask = dev.interactive() && nb.fig < n.tms, 
          use.factor.levels = TRUE, smooth = NULL, ylim = "common", 
          plot = TRUE, transform.x = FALSE, ...) 
{
  which.terms <- terms
  terms <- if (is.null(terms)) 
    predict(model, type = "terms", se.fit = se)
  else predict(model, type = "terms", se.fit = se, terms = terms)
  n.tms <- ncol(tms <- as.matrix(if (se) 
    terms$fit
    else terms))
  transform.x <- rep_len(transform.x, n.tms)
  mf <- model.frame(model)
  if (is.null(data)) 
    data <- eval(model$call$data, envir)
  if (is.null(data)) 
    data <- mf
  use.rows <- if (NROW(tms) < NROW(data)) 
    match(rownames(tms), rownames(data))
  nmt <- colnames(tms)
  if (any(grepl(":", nmt, fixed = TRUE))) 
    warning("'model' appears to involve interactions: see the help page", 
            domain = NA, immediate. = TRUE)
  cn <- parse(text = nmt, keep.source = FALSE)
  if (!is.null(smooth)) 
    smooth <- match.fun(smooth)
  if (is.null(ylabs)) 
    ylabs <- paste("Partial for", nmt)
  if (is.null(main)) 
    main <- ""
  else if (is.logical(main)) 
    main <- if (main) 
      deparse(model$call, 500)
  else ""
  else if (!is.character(main)) 
    stop("'main' must be TRUE, FALSE, NULL or character (vector).")
  main <- rep_len(main, n.tms)
  pf <- envir
  carrier <- function(term, transform) {
    if (length(term) > 1L) {
      if (transform) 
        tms[, i]
      else carrier(term[[2L]], transform)
    }
    else eval(term, data, enclos = pf)
  }
  carrier.name <- function(term) {
    if (length(term) > 1L) 
      carrier.name(term[[2L]])
    else as.character(term)
  }
  in.mf <- nmt %in% names(mf)
  is.fac <- sapply(nmt, function(i) i %in% names(mf) && is.factor(mf[, 
                                                                     i]))
  if (!plot) {
    outlist <- vector("list", sum(in.mf))
    for (i in 1L:n.tms) {
      if (!in.mf[i]) 
        next
      if (is.fac[i]) {
        xx <- mf[, nmt[i]]
        if (!is.null(use.rows)) 
          xx <- xx[use.rows]
        ww <- match(levels(xx), xx, nomatch = 0L)
      }
      else {
        xx <- carrier(cn[[i]], transform.x[i])
        if (!is.null(use.rows)) 
          xx <- xx[use.rows]
        ww <- match(sort(unique(xx)), xx)
      }
      outlist[[i]] <- if (se) 
        data.frame(x = xx[ww], y = tms[ww, i], se = terms$se.fit[ww, 
                                                                 i], row.names = NULL)
      else data.frame(x = xx[ww], y = tms[ww, i], row.names = NULL)
    }
    attr(outlist, "constant") <- attr(terms, "constant")
    if (se && is.null(attr(outlist, "constant"))) 
      attr(outlist, "constant") <- attr(terms$fit, "constant")
    names(outlist) <- sapply(cn, carrier.name)[in.mf]
    return(outlist)
  }
  if (!is.null(smooth)) 
    smooth <- match.fun(smooth)
  if (is.null(ylabs)) 
    ylabs <- paste("Partial for", nmt)
  if (is.null(main)) 
    main <- ""
  else if (is.logical(main)) 
    main <- if (main) 
      deparse(model$call, 500)
  else ""
  else if (!is.character(main)) 
    stop("'main' must be TRUE, FALSE, NULL or character (vector).")
  main <- rep_len(main, n.tms)
  if (is.null(xlabs)) {
    xlabs <- unlist(lapply(cn, carrier.name))
    if (any(transform.x)) 
      xlabs <- ifelse(transform.x, lapply(cn, deparse), 
                      xlabs)
  }
  if (partial.resid || !is.null(smooth)) {
    pres <- residuals(model, "partial")
    if (!is.null(which.terms)) 
      pres <- pres[, which.terms, drop = FALSE]
  }
  se.poly <- function(x, iy, i, ff = 2) {
    tt <- ff * terms$se.fit[iy, i]
    polygon(c(x, rev(x)), c(tms[iy, i] + tt, rev(tms[iy, i] - tt)),
            col='grey', border=NA)
  }
  nb.fig <- prod(par("mfcol"))
  if (ask) {
    oask <- devAskNewPage(TRUE)
    on.exit(devAskNewPage(oask))
  }
  ylims <- ylim
  if (identical(ylims, "common")) {
    ylims <- if (!se) 
      range(tms, na.rm = TRUE)
    else range(tms + 1.05 * 2 * terms$se.fit, tms - 1.05 * 
                 2 * terms$se.fit, na.rm = TRUE)
    if (partial.resid) 
      ylims <- range(ylims, pres, na.rm = TRUE)
    if (rug) 
      ylims[1L] <- ylims[1L] - 0.07 * diff(ylims)
  }
  for (i in 1L:n.tms) {
    if (identical(ylim, "free")) {
      ylims <- range(tms[, i], na.rm = TRUE)
      if (se) 
        ylims <- range(ylims, tms[, i] + 1.05 * 2 * terms$se.fit[, i],
                       tms[, i] - 1.05 * 2 * terms$se.fit[, i], na.rm = TRUE)
      if (partial.resid) 
        ylims <- range(ylims, pres[, i], na.rm = TRUE)
      if (rug) 
        ylims[1L] <- ylims[1L] - 0.07 * diff(ylims)
    }
    if (!in.mf[i]) 
      next
    if (is.fac[i]) {
      ff <- mf[, nmt[i]]
      if (!is.null(model$na.action)) 
        ff <- naresid(model$na.action, ff)
      ll <- levels(ff)
      xlims <- range(seq_along(ll)) + c(-0.5, 0.5)
      xx <- as.numeric(ff)
      if (rug) {
        xlims[1L] <- xlims[1L] - 0.07 * diff(xlims)
        xlims[2L] <- xlims[2L] + 0.03 * diff(xlims)
      }
      plot(1, 0, type = "n", xlab = xlabs[i], ylab = ylabs[i], 
           xlim = xlims, ylim = ylims, main = main[i], 
           xaxt = "n", ...)
      if (use.factor.levels) 
        axis(1, at = seq_along(ll), labels = ll, ...)
      else axis(1)
      for (j in seq_along(ll)) {
        ww <- which(ff == ll[j])[c(1, 1)]
        jf <- j + c(-0.4, 0.4)
        if (se) 
          se.poly(jf, iy = ww, i = i)        
        lines(jf, tms[ww, i], col = col.term, lwd = lwd.term, 
              ...)

      }
    }
    else {
      xx <- carrier(cn[[i]], transform.x[i])
      if (!is.null(use.rows)) 
        xx <- xx[use.rows]
      xlims <- range(xx, na.rm = TRUE)
      if (rug) 
        xlims[1L] <- xlims[1L] - 0.07 * diff(xlims)
      oo <- order(xx)
      plot(xx[oo], tms[oo, i], type = "n", xlab = xlabs[i], 
           ylab = ylabs[i], xlim = xlims, ylim = ylims, 
           main = main[i], ...)
      if (se) 
        se.poly(xx[oo], iy = oo, i = i)
      lines(xx[oo], tms[oo, i], col = col.term, lwd = lwd.term)
    }
    if (partial.resid) {
      if (!is.fac[i] && !is.null(smooth)) {
        smooth(xx, pres[, i], lty = lty.smth, cex = cex, 
               pch = pch, col = col.res, col.smooth = col.smth, 
               span = span.smth, lwd=2)
      }
      else points(xx, pres[, i], cex = cex, pch = pch, 
                  col = col.res)
    }
    if (rug) {
      n <- length(xx)
      lines(rep.int(jitter(xx), rep.int(3, n)), rep.int(ylims[1L] + 
                                                          c(0, 0.05, NA) * diff(ylims), n))
      if (partial.resid) 
        lines(rep.int(xlims[1L] + c(0, 0.05, NA) * diff(xlims), 
                      n), rep.int(pres[, i], rep.int(3, n)))
    }
  }
  invisible(n.tms)
}
