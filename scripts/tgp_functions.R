
read.shape = function(shpName, path=NULL) {
  require(rgdal)
  if (is.null(path))
    path = getwd()
  fileName = paste(shpName, '.shp', sep='')    
  shp = readOGR(file.path(path, fileName), shpName)
}  

r2_adj = function(Y, X, Z, method, nperm, dummy=0) {
  ## Returns
  ## a vector of R2, R2adj, and all R2adj replicates that result from permuations
  ## Arguments
  ## Y, X, Z: are species matrix, expl matrix, covar matrix
  ## nperm: the number of permutations to perform, 
  ##  if nperm not specified the analytical r2 and/or r2adj is returned 
  ##  Note: for CCA only the permutation based r2 adj is unbiased 
  ## method: specifies "cca" or "rda"
  ## dummy: a number 0, 1 or 2 depending on how many collinear variables are in the
  ##  explanatory matrix
  ##  dummy is only necessary for the analytical R2adj calculation
  Y = as.matrix(Y)
  X = as.matrix(X)
  if (missing(Z)) {
    cca.emp = eval(parse(text= paste(method, '(Y, X)')))
    r2 = cca.emp$CCA$tot.chi / cca.emp$tot.chi 
    if (missing(nperm)) {
      n = nrow(Y)
      p = ncol(X) - dummy
      out = c(r2, 1 - (((n - 1) / (n - p - 1)) * (1 - r2)))
    }
    else {
      if (nperm <= 0)
        stop('nperm argument must either be a positive integer or not specified')
      rand.r2 = rep(NA, nperm)
      i = 1
      while (i <= nperm) {
        Xrand = X[sample(nrow(X)), ]
        cca.rand = try(eval(parse(text=paste(method, '(Y, Xrand)'))), TRUE)
        if (class(cca.rand) == 'cca') {
          rand.r2[i] = cca.rand$CCA$tot.chi
          if (i %% 100 == 0)
            print(i)
          i = i + 1
        }
      }
      out = c(r2, 
              1 - (1 / (1 - mean(rand.r2 / cca.emp$tot.chi))) * (1 - r2),
              1 - (1 / (1 - rand.r2 / cca.emp$tot.chi)) * (1 - r2))
    }
  }  
  else{
    Z = as.matrix(Z)
    cca.emp = eval(parse(text=paste(method, '(Y, X, Z)')))
    r2 = cca.emp$CCA$tot.chi / cca.emp$tot.chi
    if (missing(nperm)) {
      n = nrow(Y)
      p = ncol(X) - dummy
      out = c(r2, 1 - (((n - 1)/(n - p - 1)) * (1 - r2)))
    }
    else{
      if (nperm <= 0)
        stop('nperm argument must either be a positive integer or not specified')
      rand.r2 = rep(NA, nperm)
      i = 1
      while (i <= nperm) {
        rhold = sample(nrow(X))
        Xrand = X[rhold, ]
        Zrand = Z[rhold, ]
        cca.rand = try(eval(parse(text=paste(method, '(Y, Xrand, Zrand)'))), TRUE)
        if (class(cca.rand) == 'cca') {
          rand.r2[i] = cca.rand$CCA$tot.chi
          if (i %% 100 == 0)
            print(i)
          i = i + 1
        }
      }
      out = c(r2,
              1 - (1 / (1 - mean(rand.r2 / cca.emp$tot.chi))) * (1 - r2),
              1 - (1 / (1 - rand.r2 / cca.emp$tot.chi)) * (1 - r2))
    }  
  }
  return(out)
}

partition_r2 = function(full, X1, X2, X3, X12, X13, X23,
                        adj=TRUE, digit=3) {
  ## Partition R2 values between two (XY) or three (XYZ) classes of
  ## explanatory variables
  ## Returns:
  ## the independent and shared components of variation
  ## the two class partitioning is based on Legendre and Legendre 1998, p770-775
  ## the three class paritioning is based on Anderson & Gribble 1998
  ## Arguments:
  ## full: r2 for . ~ X1 + X2 or . ~ X1 + X2 + X3
  ## adj : boolean, if true then it expects adjusted r2 are also in the previous arguments
  ## digit : positive integer where to round the output table at
  ## Examples:
  ## from Legendre and Legendre (1998)
  ## partition_r2(.784, .450, .734, adj=F)
  ## from Anderson & Gribble (1998)
  ## partition_r2(.5050, .3467, .3772, .0794, .1073, .3004, .0889, .3367, .1252, .0205, adj=F, digit=6) * 100
  ## Citations:
  ## Legendre, P., and L. Legendre. 1998. Numerical ecology. Elsevier, Boston, Mass., USA.
  ##     p770-775
  if (missing(X3)) {
    a = full - X2
    c = full - X1
    b = full - a - c
    d = 1 - full
    part = rbind(full, a, b, c, d)
    rownames(part) = c('all = X1+X2', '[a] = X1 | X2', '[b]',
                       '[c] = X2 | X1', '[d] = Residuals')
  }
  else {
    a = full - X23
    b = full - X13
    c = full - X12
    d = full - X3 - a - b
    e = full - X1 - b - c
    f = full - X2 - a - c
    g = full - a - b - c - d - e - f
    h = 1 - full
    part = rbind(full, a, b, c, d, e, f, g, h)
    rownames(part) = c('all = X1+X2+X3', '[a] = X1 | X2+X3', '[b] = X2 | X1+X3',
                       '[c] = X3 | X1+X2', '[d]', '[e]', '[f]', '[g]', '[h] = Residuals')
  }  
  if (adj) {
    part = cbind(part, (part[ , 2] / part[1, 2]) * 100)
    part = cbind(round(part[ , 1:2], digit), round(part[ , 3], digit - 2))
    colnames(part) = c('R2', 'R2adj', '% expl')
  }  
  else {
    part = cbind(part, (part[ , 1] / part[1, 1]) * 100)
    part = cbind(round(part[ , 1], digit), round(part[ , 2], digit - 2))
    colnames(part) = c('R2', '% expl')
  }  
  return(part)
}

ordi_part = function(resp, X1, X2, X3, method, adj=TRUE, digit=3, ...) {
  ## Carries out variation partitioning using direct ordination
  ## vegan function varpart is faster and can do up to 4 classes
  ## for RDA, this function allows CCA as well
  p = list()
  if (missing(X3)) {
    full = r2_adj(resp, cbind(X1, X2), method=method, ...)
    r2_X1 = r2_adj(resp, X1, method=method, ...)
    r2_X2 = r2_adj(resp, X2, method=method, ...)
    if (adj)
      part = partition_r2(full[1:2], r2_X1[1:2], r2_X2[1:2], adj=adj,
                          digit=digit)
    else 
      part = partition_r2(full[1], r2_X1[1], r2_X2[1], adj=adj,
                          digit=digit)
    p$part = part
    p$r2$X1 = r2_X1
    p$r2$Y2 = r2_X2
  }
  else {
    full = r2_adj(resp, cbind(X1, X2, X3), method=method, ...)
    r2_X1 = r2_adj(resp, X1, method=method, ...)
    r2_X2 = r2_adj(resp, X2, method=method, ...)
    r2_X3 = r2_adj(resp, X3, method=method, ...)
    r2_X12 = r2_adj(resp, cbind(X1, X2), method=method, ...)
    r2_X13 = r2_adj(resp, cbind(X1, X3), method=method, ...)
    r2_X23 = r2_adj(resp, cbind(X2, X3), method=method, ...)
    if (adj)
      part = partition_r2(full[1:2], r2_X1[1:2], r2_X2[1:2], r2_X3[1:2], 
                          r2_X12[1:2], r2_X13[1:2], r2_X23[1:2], digit=digit)
    else
      part = partition_r2(full[1], r2_X1[1], r2_X2[1], r2_X3[1], 
                          r2_X12[1], r2_X13[1], r2_X23[1], adj=adj, digit=digit)
    p$part = part
    p$r2$X1 = r2_X1
    p$r2$X2 = r2_X2
    p$r2$X3 = r2_X3
    p$r2$X12 = r2_X12
    p$r2$X13 = r2_X13
    p$r2$X23 = r2_X23
  }
  return(p)
}

get_diam = function(diam1, perc1, perc2) {
  area1 = pi * (diam1 / 2)^2
  area2 = (area1 * perc2) / perc1
  diam2 = 2 * sqrt(area2 / pi)
  return(diam2)
}


