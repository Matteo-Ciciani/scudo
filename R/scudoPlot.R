#' Plot scudoNetwork result
#'
#' A wrapper to \code{\link[igraph]{plot.igraph}} and
#' \code{\link[graphics]{legend}}. Can be used to plot the result of
#' \code{\link{scudoNetwork}} with a color legend.
#'
#' @param net an \code{\link[igraph:aaa-igraph-package]{igraph}} object returned
#' by \code{scudoNetwork}
#'
#' @param x,y the x and y coordinates to be used to position the legend. They
#' can be specified by keyword or in any way which is accepted by
#' \code{\link[grDevices]{xy.coords}}. See Details of
#' \code{\link[graphics]{legend}}
#'
#' @param ... arguments to be passed to \code{\link[igraph]{plot.igraph}}
#'
#' @return Returns \code{NULL}, invisibly.
#'
#' @author Matteo Ciciani \email{matteo.ciciani@@gmail.com}, Thomas Cantore
#' \email{cantorethomas@@gmail.com}
#'
#' @seealso \code{\link{scudoNetwork}}, \code{\link[igraph]{plot.igraph}}
#'
#' @examples
#' # generate dummy dataset, run scudoTrain and scudoNetwork
#' exprData <- data.frame(a = 11:20, b = 16:25,
#'     c = rev(1:10), d = c(1:2, rev(3:10)))
#' rownames(exprData) <- letters[11:20]
#' grps <- as.factor(c("G1", "G1", "G2", "G2"))
#' nTop <- 2
#' nBottom <- 3
#' res <- scudoTrain(exprData, grps, nTop, nBottom, foldChange = FALSE,
#'     featureSel = FALSE)
#' net <- scudoNetwork(res, N = 0.5)
#'
#' # Plot with scudoPlot
#' scudoPlot(net)
#'
#' @export
scudoPlot <- function(net, x = "bottomright", y = NULL, ...) {
    igraph::plot.igraph(net, ...)
    if (!is.null(igraph::V(net)$group)) {
        df <- unique(data.frame(igraph::V(net)$color, igraph::V(net)$group,
            stringsAsFactors = FALSE))
        graphics::legend(x, y, legend = df[, 2],
            col = df[, 1], pch=c(15,15),
            pt.cex=2)
    }
}
