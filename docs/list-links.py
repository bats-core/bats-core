import pickle
with open("build/doctrees/environment.pickle", "rb") as f:
    dat = pickle.load(f)
print(dat.domaindata['std']['labels'])
