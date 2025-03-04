# # Simple example of plotting a phylogeny
using CairoMakie, BasicTreePlots, NewickTree

tree =
    nw"(Human_coronavirus_NL63__YP_003767.1:0.2837167697,((((Coronavirus_AcCoV-JC34__YP_009380521.1:0.1753779846,Lucheng_Rn_rat_coronavirus__YP_009336484.1:0.1823729640):1.5633499702,(((((Murine_hepatitis_virus__NP_045300.1:0.0465644139,Murine_hepatitis_virus_strain_JHM__YP_209233.1:0.0400825485):0.0771107289,Rat_coronavirus_Parker__YP_003029848.1:0.1042243458):0.1303858841,(Human_coronavirus_HKU1__YP_173238.1:0.2884582318,(((Bovine_coronavirus__NP_150077.1:0.0252424258,Human_coronavirus_OC43__YP_009555241.1:0.0522904576):0.0109027241,Rabbit_coronavirus_HKU14__YP_005454245.1:0.0242597338):0.1634381639,Betacoronavirus_HKU24__YP_009113025.1:0.2237054710):0.0754395643):0.0399072843):0.8784475802,(((Pipistrellus_bat_coronavirus_HKU5__YP_001039962.1:0.2087545259,Tylonycteris_bat_coronavirus_HKU4__YP_001039953.1:0.1665826056):0.0840068345,(Betacoronavirus_England_1__YP_007188579.1:0.0015006674,Middle_East_respiratory_syndrome-related_coronavirus__YP_009047204.1:0.0000023308):0.2345306605):0.1724797525,Betacoronavirus_Erinaceus_VMC_DEU_2012__YP_009513010.1:0.2475827909):0.8267565826):0.1812279915,(((Severe_acute_respiratory_syndrome_coronavirus_2__YP_009724390.1:0.1322988464,Severe_acute_respiratory_syndrome-related_coronavirus__NP_828851.1:0.0988541333):0.5863592327,Bat_Hp-betacoronavirus_Zhejiang2013__YP_009072440.1:0.4591408199):0.4969413816,(Rousettus_bat_coronavirus__YP_009273005.1:0.2912220426,Rousettus_bat_coronavirus_HKU9__YP_001039971.1:0.2774975608):0.7498515344):0.1300788194):0.2026176920):0.6317604948,(Infectious_bronchitis_virus__NP_040831.1:0.7413582696,Turkey_coronavirus__YP_001941166.1:0.4175214245):0.3538495234):0.8226529179,BtMr-AlphaCoV_SAX2011__YP_009199609.1:0.4416013419):0.2205284043,Human_coronavirus_229E__NP_073551.1:0.2265542283);"

fig = Figure(size = (500, 600))
ax = Axis(fig[1, 1]; xautolimitmargin = (0.05, 2.0), xticks = 0:4)
hideydecorations!(ax)
hidespines!(ax, :l, :r, :t)
treeplot!(tree)
fig
