export const deepReplacePlaceholders = (target: any, replacements: Record<string, string>) => {
    if (typeof target === 'object') {
        for (let key in target) {
            if (typeof target[key] === 'object') {
                deepReplacePlaceholders(target[key], replacements);
            } else if (typeof target[key] === 'string') {
                for (const [placeholder, value] of Object.entries(replacements)) {
                    if (target[key].includes(placeholder)) {
                        // console.log(target[key]);
                        target[key] = target[key].replaceAll(placeholder, value)
                    }

                    if (target[key].includes('QRCode')) {

                        target.text = replacements['{bugUrl}'] || target[key];
                    }

                }
            }
        }
    }
    return target
}
