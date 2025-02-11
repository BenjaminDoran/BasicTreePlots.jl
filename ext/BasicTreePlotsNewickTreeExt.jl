module BasicTreePlotsNewickTreeExt

import BasicTreePlots, NewickTree

BasicTreePlots.distance(n::NewickTree.Node) = begin
    d = NewickTree.distance(n)
    isfinite(d) ? d : zero(typeof(d))
end
BasicTreePlots.label(n::NewickTree.Node) = NewickTree.name(n)

end
