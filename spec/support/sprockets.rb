# disable AssetNotPrecompiledError
module SprocketsAssetNotPrecompiledErrorFixer
  def raise_unless_precompiled_asset(path)
  end
end

Sprockets::Rails::HelperAssetResolvers::Environment.prepend(SprocketsAssetNotPrecompiledErrorFixer)
