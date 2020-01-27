# clean workspace
rm(list=ls())

#setwd("/home/pedro/Dropbox/Mestrado/Disciplinas/Planejamento e An√°lise Experimentos/Trabalhos/Projeto Final/Resultados piloto")
setwd('D:/Dropbox/Dropbox/Mestrado/Disciplinas/Planejamento e An·lise Experimentos/Trabalhos/Projeto Final')

data <- read.csv2("results.csv", sep = ',', encoding = "UTF-8")

# Aggregate data (algorithm means by instance group)
aggdata <- with(data, aggregate(x   = as.numeric(Result), by  = list(Local.Search.Type, Problem), FUN = mean))

# Rename columns
names(aggdata) <- c("Config",
                    "Problem", 
                    "Y")

# Coerce categorical variables to factors
for (i in 1:2){
  aggdata[, i] <- as.factor(aggdata[, i])
}

summary(aggdata)

# Exploratory data analysis: plot observations by Algorithm and Instance_Group
library(ggplot2)

p <- ggplot(aggdata, aes(x = Problem, 
                         y = Y, 
                         group = Config, 
                         colour = Config))
p + geom_line(linetype=2) + geom_point(size=5)

# Statistical modeling
# First model
model <- aov(Y~Config+Problem,
             data = aggdata)
summary(model)
summary.lm(model)$r.squared

# Graphical test of assumptions
par(mfrow = c(2, 2))
plot(model, pch = 20, las = 1)

library(car)
par(mfrow = c(1, 1))
qqPlot(model$residuals, pch = 20, las = 1, lwd =2)
shapiro.test(model$residuals)

fligner.test(Y ~ Config, data = aggdata)
fligner.test(Y ~ Problem, data = aggdata)

plot(x = model$fitted.values, y = model$residuals)

# Blocking efficiency
mydf        <- as.data.frame(summary(model)[[1]])
MSblocks    <- mydf["Problem","Mean Sq"]
MSe         <- mydf["Residuals","Mean Sq"]
a           <- length(unique(aggdata$Config))
b           <- length(unique(aggdata$Problem))
((b - 1) * MSblocks + b * (a - 1) * MSe) / ((a * b - 1) * MSe)

library(multcomp)
tuktest     <- glht(model, linfct = mcp(Config = "Tukey"))

tuktestCI   <- confint(tuktest)

par(mar = c(5, 8, 4, 2), las = 1, lwd = 3)
plot(tuktestCI, xlab = "Mean difference")