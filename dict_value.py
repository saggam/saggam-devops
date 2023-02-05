def get_value(dictionary, keys):
    value = dictionary
    for key in keys:
        value = value.get(key)
        if value is None:
            return None
    return value

#d = {"w":{"x":{"y":"z"}}}
#keys = ['w','x','y']
#print(get_value(d, keys))