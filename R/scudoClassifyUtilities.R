#' @include utilities.R
NULL

.classifyInputCheck <- function(trainExpData, N, nTop, nBottom,
    trainGroups, neighbors, weighted, complete, beta, alpha, foldChange,
    featureSel, logTransformed,  parametric, pAdj, distFun) {

    # checks on N, nTop, nBottom -----------------------------------------------

    stopifnot(.isSinglePositiveNumber(N),
        N <= 1.0,
        .isSinglePositiveInteger(nTop),
        .isSinglePositiveInteger(nBottom))

    # checks on trainGroups, testGroups ----------------------------------------

    stopifnot(is.factor(trainGroups))

    if (any(is.na(trainGroups))) {
        stop("trainGroups contains NAs.")
    }

    if (length(trainGroups) != dim(trainExpData)[2]) {
        stop(paste("Length of trainGroups is different from number of columns",
            "of trainExpData"))
    }

    if (length(levels(trainGroups))  < 2) {
        stop("trainGroups must contain at least 2 groups")
    }

    # check neighbors, beta, weighted, complete --------------------------------

    stopifnot(.isSinglePositiveInteger(neighbors),
        .isSinglePositiveNumber(beta),
        .isSingleLogical(weighted),
        .isSingleLogical(complete))

    # check other parameters, use placeholder for groupedFoldChange ------------

    .checkParams(alpha, foldChange, TRUE, featureSel, logTransformed,
        parametric, pAdj, distFun)

}

.computeTestNetwork <- function(dMatrix, N, trainGroups) {
    result <- .makeNetwork(dMatrix, N)
    # add groups
    igraph::V(result)$group <- c("0", as.character(trainGroups))
    result
}

.networksFromDistMatrix <- function(dMatrix, N, trainGroups) {
    nTrain <- length(trainGroups)
    iTest <- (nTrain + 1):(dim(dMatrix)[1])
    minimized <- lapply(iTest, function(i) .minimize(dMatrix[c(i,
        seq_len(nTrain)), c(i, seq_len(nTrain))]))
    lapply(minimized, .computeTestNetwork, N, trainGroups)
}

.getScores <- function(net, root, nodes) {
    i <- vapply(names(nodes), function(x) igraph::get.edge.ids(net,
        c(names(root), x), directed = FALSE), numeric(1))
    2 - igraph::get.edge.attribute(net, "distance", i)
}

.visitEdges <- function(net, maxDist, groups, weighted, beta) {
    root <- igraph::V(net)[1]
    bfsRes <- igraph::bfs(net, root, unreachable = FALSE, dist = TRUE)
    toVisit <- rep(FALSE, length(igraph::V(net)))
    toVisit[bfsRes$dist <= maxDist - 1] <- TRUE
    finished <- rep(FALSE, length(igraph::V(net)))
    groupScores <- rep(0, length(groups))
    names(groupScores) <- groups

    while (any(toVisit)) {
        u <- igraph::V(net)[toVisit][1]
        toVisit[as.integer(u)] <- FALSE
        firstNeighbors <- igraph::neighborhood(net, nodes = u, mindist = 1)[[1]]
        firstNeighbors <- firstNeighbors[!(firstNeighbors %in%
            igraph::V(net)[finished])]
        neighborsGroups <- as.factor(firstNeighbors$group)
        if (weighted) {
            neighborsScores <- .getScores(net, u, firstNeighbors)
        } else {
            neighborsScores <- rep(1, length(neighborsGroups))
        }
        coeff1 <- rep(1, length(firstNeighbors))
        coeff1[bfsRes$dist[firstNeighbors] == bfsRes$dist[u]] <- 0.5
        coeff2 <- beta ^ bfsRes$dist[u]
        neighborsScores <- coeff1 * coeff2 * neighborsScores
        newScores <- vapply(split(neighborsScores, neighborsGroups), sum,
                            numeric(1))
        groupScores[as.character(levels(neighborsGroups))] <- groupScores[
            as.character(levels(neighborsGroups))] + newScores
        if (any(toVisit) && min(bfsRes$dist[toVisit]) >  bfsRes$dist[u]) {
            finished[bfsRes$dist == bfsRes$dist[u]] <- TRUE
        }
    }

    groupScores <- groupScores / sum(groupScores)
    groupScores
}

.computeScores <- function(dMatrix, N, trainGroups, maxDist, weighted, beta) {
    # make test networks and run weighted edge visit on each network
    nets <- .networksFromDistMatrix(dMatrix, N, trainGroups)
    scores <- lapply(nets, .visitEdges, maxDist, levels(trainGroups), weighted,
        beta)
    scores <- t(as.data.frame(scores))
    rownames(scores) <- colnames(dMatrix)[
        (length(trainGroups) + 1):(dim(dMatrix)[2])]
    scores
}

.computeCompleteScores <- function(distMat, nTrain, nTest, trainGroups) {
    distMat <- 2 - distMat[seq_len(nTrain), seq(nTrain + 1, nTrain + nTest)]

    # get sums for each new sample
    scores <- stats::aggregate(distMat, by = list(trainGroups),
        FUN = sum)
    scores <- scores[, -1] / table(trainGroups)
    scores <- t(apply(scores, 2, function(x) x/sum(x)))
    colnames(scores) <- levels(trainGroups)

    scores
}
